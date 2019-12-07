class ref IOQueue
  let _buffer: Array[I64]

  new create() =>
    _buffer = Array[I64].create()

  fun ref get(): (I64 | None) =>
    try _buffer.pop()? else None end

  fun ref put(x: I64) =>
    _buffer.unshift(x)

class Program
  var _op_len: USize
  var _current_op: Array[U8]
  var _pc: USize
  var _memory: Array[I64]
  let _in_queue: IOQueue
  let _out_queue: IOQueue
  var finished: Bool = false

  new create(in_queue: IOQueue, out_queue: IOQueue, arr: Array[I64] val) =>
    _memory = arr.clone()
    _pc = 0
    _op_len = 5
    _current_op = Array[U8].init(0, _op_len)
    _in_queue = in_queue
    _out_queue = out_queue

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

  fun ref _execute_add()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    let target = _memory(_pc + 3)?.usize()
    _memory.update(target, (arg_1 + arg_2))?
    _pc = _pc + 4

  fun ref _execute_mul()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    let target = _memory(_pc + 3)?.usize()
    _memory.update(target, (arg_1 * arg_2))?
    _pc = _pc + 4

  fun ref _execute_input()? =>
    match _in_queue.get()
    | None => None
    | let i: I64 =>
      _memory.update(_memory(_pc + 1)?.usize(), i)?
      _pc = _pc + 2
    end

  fun ref _execute_output()? =>
    let target = match _current_op(2)?
      | 0 => _memory(_memory(_pc + 1)?.usize())?
      | 1 => _memory(_pc + 1)?
    else
      error
    end

    _out_queue.put(target)
    _pc = _pc + 2

  fun ref _execute_jit()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    _pc = if arg_1 != 0 then arg_2.usize() else _pc + 3 end

  fun ref _execute_jif()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    _pc = if arg_1 == 0 then arg_2.usize() else _pc + 3 end

  fun ref _execute_lt()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    let target = _memory(_pc + 3)?.usize()
    _memory.update(target, (if arg_1 < arg_2 then 1 else 0 end))?
    _pc = _pc + 4

  fun ref _execute_eq()? =>
    (let arg_1, let arg_2) = _get_arith_args()?
    let target = _memory(_pc + 3)?.usize()
    _memory.update(target, (if arg_1 == arg_2 then 1 else 0 end))?
    _pc = _pc + 4

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
      | 1 => _execute_add()?
      | 2 => _execute_mul()?
      | 3 => _execute_input()?
      | 4 => _execute_output()?
      | 5 => _execute_jit()?
      | 6 => _execute_jif()?
      | 7 => _execute_lt()?
      | 8 => _execute_eq()?
      else
        error
      end
    end
