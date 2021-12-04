use "collections"

class Board
  let _idx: MapIs[U32, (USize, USize)] = _idx.create()
  var _next_row: USize = 0
  let _b: Array[Array[U32]] = _b.create()

  let _crossed: SetIs[U32] = _crossed.create()
  let _rows_crossed: Array[U32] = Array[U32].init(0, 5)
  let _columns_crossed: Array[U32] = Array[U32].init(0, 5)

  new create() => None

  fun ref push_row(line: Array[U32] box) ? =>
    if _next_row > 5 then error end

    let row = Array[U32].init(0, 5)
    for (col, number) in line.pairs() do
      row(col)? = number
      _idx.insert(number, (_next_row, col))
    end
    _b.push(row)
    _next_row = _next_row + 1

  fun ref mark_ball(ball: U32) =>
    if _idx.contains(ball) then
      try
        _crossed.set(ball)
        (let row, let col) = _idx(ball)?
        _rows_crossed(row)? = _rows_crossed(row)? + 1
        _columns_crossed(col)? = _columns_crossed(col)? + 1
      end
    end

  fun is_bingo(): Bool =>
    for c in _rows_crossed.values() do
      if c == 5 then
        return true
      end
    end

    for c in _columns_crossed.values() do
      if c == 5 then
        return true
      end
    end

    false

  fun sum_unmarked(): U64 =>
    var sum: U64 = 0
    for n in _idx.keys() do
      if not _crossed.contains(n) then
        sum = sum + n.u64()
      end
    end
    sum

  fun string(): String iso^ =>
    let str = recover String end
    for row in _b.values() do
      for number in row.values() do
        str.>append(number.string()).append(" ")
      end
      str.append("\n")
    end
    consume str
