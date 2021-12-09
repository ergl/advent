use "../../2019/graph"

use "files"
use "itertools"
use "collections"

class val Coord is (Comparable[Coord] & Equatable[Coord])
  let col: I64
  let row: I64

  new val create(row': I64, col': I64) =>
    col = col'
    row = row'

  fun eq(that: box->Coord): Bool =>
    (col == that.col) and (row == that.row)

  fun lt(that: box->Coord): Bool =>
    if col == that.col then
      row < that.row
    else
      col < that.col
    end

  fun string(): String iso^ =>
    "(" + col.string() + "," + row.string() + ")"

class val CoordHash is HashFunction[Coord]
  new val create() => None

  fun hash(c: Coord): USize =>
    let row = c.row.hash()
    let col = c.col.hash()
    let tmp = col + 0x9e3779b9 + (row << 6) + (row >> 2)
    row xor tmp

  fun eq(left: Coord, right: Coord): Bool => left == right

class Board
  let _repr: MapIs[(I64, I64), I64]
  let _rows: I64
  let _cols: I64

  new create(from: MapIs[(I64, I64), I64], rows': I64, cols': I64) =>
    _repr = from
    _rows = rows'
    _cols = cols'

  fun cols(): I64 => _cols
  fun rows(): I64 => _rows

  fun low_point_risk(): I64 =>
    var risk: I64 = 0
    for ((row, col), value) in _repr.pairs() do
      let up = _repr.get_or_else((row, col - 1), I64.max_value())
      let down = _repr.get_or_else((row, col + 1), I64.max_value())
      let left = _repr.get_or_else((row - 1, col), I64.max_value())
      let right = _repr.get_or_else((row + 1, col), I64.max_value())
      if
        (up > value) and
        (down > value) and
        (left > value) and
        (right > value)
      then
        // Risk is elevation plus one
        risk = risk + (value + 1)
      end
    end
    risk

  fun basin_sizes(): Array[USize] =>
    let g = _board_to_graph()
    let sizes = Array[USize].create()
    for point in low_points().values() do
      let s = _basin_size(point, g)
      sizes.push(s)
    end
    sizes

  fun low_points(): Array[(I64, I64)] =>
    let points = Array[(I64, I64)].create()
    for ((row, col), value) in _repr.pairs() do
      let up = _repr.get_or_else((row, col - 1), I64.max_value())
      let down = _repr.get_or_else((row, col + 1), I64.max_value())
      let left = _repr.get_or_else((row - 1, col), I64.max_value())
      let right = _repr.get_or_else((row + 1, col), I64.max_value())
      if
        (up > value) and
        (down > value) and
        (left > value) and
        (right > value)
      then
        points.push((row, col))
      end
    end
    points

  fun _neighbors(
    point: (I64, I64))
    : Array[Coord]
  =>
    let neig = Array[Coord].create(4)
    (let row, let col) = point
    if _repr.get_or_else((row, col - 1), 9) != 9 then
      neig.push(Coord.create(row, col - 1))
    end
    if _repr.get_or_else((row, col + 1), 9) != 9 then
      neig.push(Coord.create(row, col + 1))
    end
    if _repr.get_or_else((row - 1, col), 9) != 9 then
      neig.push(Coord.create(row - 1, col))
    end
    if _repr.get_or_else((row + 1, col), 9) != 9 then
      neig.push(Coord.create(row + 1, col))
    end
    neig

  fun _board_to_graph(): Graph[Coord, CoordHash] =>
    let g = Graph[Coord, CoordHash].create()
    for ((row, col), value) in _repr.pairs() do
      if value == 9 then
        // We don't want to store these vertices
        continue
      else
        let as_coord = Coord.create(row, col)
        g.add_vertex(as_coord)
        for n in _neighbors((row, col)).values() do
          g.add_vertex(n)
          g.add_edge(as_coord, n)
        end
      end
    end
    g

  fun _basin_size(
    starting: (I64, I64),
    g: Graph[Coord, CoordHash] box)
    : USize
  =>
    let visited = HashSet[Coord, CoordHash]
    _traverse(Coord.create(starting._1, starting._2), g, visited)
    visited.size()

  fun _traverse(
    v: Coord,
    g: Graph[Coord, CoordHash] box,
    visited: HashSet[Coord, CoordHash])
  =>
    visited.set(v)
    for v' in g.neighbors(v) do
      if not visited.contains(v') then
        _traverse(v', g, visited)
      end
    end

  fun string(): String iso^ =>
    let s = recover String.create((_rows * _cols).usize()) end
    var row: I64 = 0
    while row < _rows do
      var col: I64 = 0
      while col < _cols do
        try
          s.push(_repr((row, col))?.u8() + 48)
        end
        col = col + 1
      end
      s.push('\n')
      row = row + 1
    end
    consume s

primitive ParseBoard
  fun apply(lines: FileLines): Board =>
    let board = MapIs[(I64, I64), I64].create() 
    var row: I64 = 0
    var total_colums: I64 = 0
    for line in lines do
      var column: I64 = 0
      for byte in (consume line).values() do
        board.insert((row, column), (byte - 48).i64())
        column = column + 1
      end
      if column > total_colums then
        total_colums = column
      end
      row = row + 1
    end
    Board.create(board, row, total_colums)

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let board = ParseBoard(file.lines())
        silver(env.out, board)
        gold(env.out, board)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, board: Board box) =>
    out.print("Risk for board is: " + board.low_point_risk().string())

  fun tag gold(out: OutStream, board: Board box) =>
    var sizes = board.basin_sizes()
    sizes = Sort[Array[USize], USize](sizes)
    try
      let final_size =
        sizes(sizes.size() - 1)? *
        sizes(sizes.size() - 2)? *
        sizes(sizes.size() - 3)?
      out.print("Total basin size: " + final_size.string())
    end
