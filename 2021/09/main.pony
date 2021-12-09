use "files"
use "itertools"
use "collections"

class Board
  let _repr: MapIs[(I64, I64), I64]
  let _rows: I64
  let _cols: I64

  new create(from: MapIs[(I64, I64), I64], rows: I64, cols: I64) =>
    _repr = from
    _rows = rows
    _cols = cols

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
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, board: Board box) =>
    out.print("Risk for board is: " + board.low_point_risk().string())
