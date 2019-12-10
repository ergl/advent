use "files"
use "itertools"

primitive Utils
  fun parse_input(input: String): I64 =>
    try input.i64()? else 0 end

class Program
  // [A, B, C, D, E]
  // A(0) => mode of third parameter
  // B(1) => mode of second parameter
  // C(2) => mode of first parameter
  // C(3) and C(4) => opcodes
  // parameter mode
  // 0 -> position (number denotes the address of the value)
  // 1 -> immediate (number is the value)
  var _op_len: USize
  var _current_op: Array[U8]
  var _pc: USize
  var _memory: Array[I64]
  let _stdin: Array[I64]
  let _stdout: Array[String val]
  var finished: Bool = false

  new create(stdin: Array[I64] iso, stdout: Array[String val] iso, arr: Array[I64] iso) =>
    _memory = consume arr
    _pc = 0
    _op_len = 5
    _current_op = Array[U8].init(0, _op_len)
    _stdin = consume stdin
    _stdout = consume stdout

  // Fill the _current_op array with data
  fun ref _parse_op(i: I64) =>
    try
      var idx = (_op_len - 1)
      var q = i
      var r: I64 = 0

      while idx >= 0 do
        (q, r) = q.divrem(10)
        _current_op.update(idx, r.u8())?
        idx = idx - 1
      end
    end

  fun ref _execute_add() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      let target = _memory(_pc + 3)?.usize()
      _memory.update(target, (arg_1 + arg_2))?
    end

  fun ref _execute_mul() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      let target = _memory(_pc + 3)?.usize()
      _memory.update(target, (arg_1 * arg_2))?
    end

  fun ref _execute_input() =>
    try
      _memory.update(_memory(_pc + 1)?.usize(), _stdin.shift()?)?
    end

  fun ref _execute_output() =>
    try
      let target = match _current_op(2)?
      | 0 => _memory(_memory(_pc + 1)?.usize())?
      | 1 => _memory(_pc + 1)?
      else
        error
      end

      _stdout.push(target.string())
    end

  fun ref _execute_jit() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      _pc = if arg_1 != 0 then arg_2.usize() else _pc + 3 end
    end

  fun ref _execute_jif() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      _pc = if arg_1 == 0 then arg_2.usize() else _pc + 3 end
    end

  fun ref _execute_lt() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      let target = _memory(_pc + 3)?.usize()
      _memory.update(target, (if arg_1 < arg_2 then 1 else 0 end))?
    end

  fun ref _execute_eq() =>
    try
      (let arg_1, let arg_2) = _get_arith_args()?
      let target = _memory(_pc + 3)?.usize()
      _memory.update(target, (if arg_1 == arg_2 then 1 else 0 end))?
    end

  fun ref _get_arith_args(): (I64, I64)? =>
    let fm = _current_op(2)?
    let sm = _current_op(1)?
    match (fm, sm)
    | (0, 0) =>
      (_memory(_memory(_pc + 1)?.usize())?, _memory(_memory(_pc + 2)?.usize())?)
    | (0, 1) =>
      (_memory(_memory(_pc + 1)?.usize())?, _memory(_pc + 2)?)
    | (1, 0) =>
      (_memory(_pc + 1)?, _memory(_memory(_pc + 2)?.usize())?)
    | (1, 1) =>
      (_memory(_pc + 1)?, _memory(_pc + 2)?)
    else
      error
    end

  fun ref step() =>
    try
      var opcode = _memory(_pc)?
      if opcode == 99 then
        finished = true
        return
      end

      _parse_op(opcode)
      let op = _current_op(4)?
      match op
      | 1 => _execute_add(); _pc = _pc + 4
      | 2 => _execute_mul(); _pc = _pc + 4
      | 3 => _execute_input(); _pc = _pc + 2
      | 4 => _execute_output(); _pc = _pc + 2
      | 5 => _execute_jit()
      | 6 => _execute_jif()
      | 7 => _execute_lt(); _pc = _pc + 4
      | 8 => _execute_eq(); _pc = _pc + 4
      else
        error
      end
    end

  fun ref flush_stdout(out: OutStream) =>
    for v in _stdout.values() do
      out.print(v)
    end

actor Main
  var path: String = "./05/input.txt"

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      do
        let program_arr: Array[I64] iso = recover
          Iter[String](file.read_string(file.size()).split_by(",").values())
            .map[I64]({(elt) => Utils.parse_input(elt)})
            .collect(Array[I64](10))
        end

        let stdin = recover [as I64: 5] end
        let stdout = recover Array[String].create(10) end

        let program = Program.create(consume stdin, consume stdout, consume program_arr)
        while not program.finished do
          program.step()
        end

        env.out.print("Output")
        program.flush_stdout(env.out)
      end
    else
      env.out.print("Couldn't open ".add(path))
    end
