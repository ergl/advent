primitive Add
primitive Mul
primitive Input
primitive Output
primitive JT
primitive JF
primitive Lt
primitive Eq
primitive Halt
type Opcode is (Add | Mul | Input | Output | JT | JF | Lt | Eq | Halt)

primitive Position
primitive Immediate
type Mode is (Position | Immediate)

class Instruction
  let _len: USize
  let _arr: Array[U8]

  new create(len: USize) =>
    _len = len
    _arr = Array[U8].init(0, _len)

  fun ref parse(i: I64) =>
    try
      var idx = _len - 1
      var q = i
      var r: I64 = 0

      while idx >= 0 do
        (q ,r) = q.divrem(10)
        _arr(idx)? = r.u8()
        (idx, let overflow) = idx.subc(1)
        if overflow then break end
      end
    end

  fun opcode(): Opcode =>
    let last_op = try _arr(_len - 1)? else 9 end
    let first_op = try _arr(_len - 2)? else 9 end
    match (first_op, last_op)
      | (9, 9) => Halt
      | (_, 1) => Add
      | (_, 2) => Mul
      | (_, 3) => Input
      | (_, 4) => Output
      | (_, 5) => JT
      | (_, 6) => JF
      | (_, 7) => Lt
      | (_, 8) => Eq
    else
      Halt
    end

  fun first_mode(): Mode =>
    _get_mode(_len - 3)

  fun second_mode(): Mode =>
    _get_mode(_len - 4)

  fun third_mode(): Mode =>
    _get_mode(_len - 5)

  fun _get_mode(idx: USize): Mode =>
    let mode = try _arr(idx)? else 0 end
    match mode
    | 0 => Position
    | 1 => Immediate
    else Position
    end
