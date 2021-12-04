use "files"
use "itertools"

primitive ParseFile
  fun apply(lines: FileLines): (Array[U32], Array[Board]) =>
    let balls = Array[U32]
    let boards = Array[Board]
    try
      var first = true
      var in_board = false
      var board_idx: USize = 0
      var tmp_board = Board

      for line in lines do
        if first then
          first = false
          for b in line.split(",").values() do
            balls.push(b.read_int[U32](0, 10)?._1)
          end
          continue
        end

        if line.size() == 0 then
          continue
        end

        if board_idx < 5 then
          let row = Iter[String](line.split(" ").values())
            .filter({(elt) => elt.size() != 0})
            .map[U32]({(elt)? => elt.read_int[U32](0, 10)?._1})
            .collect(Array[U32])
          tmp_board.push_row(row)?
          board_idx = board_idx + 1
          if board_idx == 5 then
            boards.push(tmp_board)
            tmp_board = Board
            board_idx = 0
          end
        end
      end
    end
    (balls, boards)
