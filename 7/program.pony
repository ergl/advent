use "collections"

class Memory
  let _mem: MapIs[USize, I64]

  new create(program: Array[I64] val) =>
    let len = program.size()
    _mem = MapIs[USize, I64].create(len)
    for i in Range.create(0, len) do
      _mem.insert(i, try program(i)? else 0 end)
    end

  fun apply(idx: USize): I64 =>
    try _mem(idx)? else 0 end

  fun ref update(idx: USize, value: I64) =>
    _mem(idx) = value
    None

class Program
  var _pc: USize
  let _in_queue: IOQueue
  let _memory: Memory
  var _relative_offset: I64
  let _out_fn: {(I64): None}
  var finished: Bool = false
  let _current_instruction: Instruction

  new create(in_queue: IOQueue, out_fn: {(I64): None}, arr: Array[I64] val) =>
    _pc = 0
    _out_fn = out_fn
    _relative_offset = 0
    _in_queue = in_queue
    _memory = Memory.create(arr)
    _current_instruction = Instruction.create(5)

  fun _get_first_arg(): I64 =>
    let content = _memory(_pc + 1)
    match _current_instruction.first_mode()
    | Immediate => content
    | Position => _memory(content.usize())
    | Relative => _memory((_relative_offset + content).usize())
    end

  fun _get_second_arg(): I64 =>
    let content = _memory(_pc + 2)
    match _current_instruction.second_mode()
    | Immediate => content
    | Position => _memory(content.usize())
    | Relative => _memory((_relative_offset + content).usize())
    end

  fun _get_target_arg(): USize =>
    (let target_pos, let mode) = match _current_instruction.opcode()
    | Input => (_memory(_pc + 1), _current_instruction.first_mode())
    else (_memory(_pc + 3), _current_instruction.third_mode()) end

    match mode
    | Relative => (_relative_offset + target_pos).usize()
    else target_pos.usize() end

  fun ref _execute_add() =>
    _memory(_get_target_arg()) = _get_first_arg() + _get_second_arg()
    _pc = _pc + 4

  fun ref _execute_mul() =>
    _memory(_get_target_arg()) = _get_first_arg() * _get_second_arg()
    _pc = _pc + 4

  fun ref _execute_input() =>
    match _in_queue.get()
    | None => None
    | let i: I64 =>
      _memory(_get_target_arg()) = i
      _pc = _pc + 2
    end

  fun ref _execute_output() =>
    _out_fn(_get_first_arg())
    _pc = _pc + 2

  fun ref _execute_jit() =>
    _pc = if _get_first_arg() != 0 then _get_second_arg().usize() else _pc + 3 end

  fun ref _execute_jif() =>
    _pc = if _get_first_arg() == 0 then _get_second_arg().usize() else _pc + 3 end

  fun ref _execute_lt() =>
    _memory(_get_target_arg()) = if _get_first_arg() < _get_second_arg() then 1 else 0 end
    _pc = _pc + 4

  fun ref _execute_eq() =>
    _memory(_get_target_arg()) = if _get_first_arg() == _get_second_arg() then 1 else 0 end
    _pc = _pc + 4

  fun ref _execute_offset() =>
    _relative_offset = _relative_offset + _get_first_arg()
    _pc = _pc + 2

  fun ref step() =>
    let inst_number = _memory(_pc)
    _current_instruction.parse(inst_number)
    match _current_instruction.opcode()
    | Halt => finished = true
    | Add => _execute_add()
    | Mul => _execute_mul()
    | Input => _execute_input()
    | Output => _execute_output()
    | JT => _execute_jit()
    | JF => _execute_jif()
    | Lt => _execute_lt()
    | Eq => _execute_eq()
    | Offset => _execute_offset()
    end
