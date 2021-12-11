use "files"
use "collections"

use "debug"

type Board is MapIs[(I64, I64), USize]

primitive PrintBoard
  fun apply(board: Board box): String iso^ =>
    let str = recover String.create(100) end
    for row in Range[I64](0, 10) do
      for col in Range[I64](0, 10) do
        str.push(
          (board.get_or_else((row, col), 0) + 48).u8()
        )
      end
      str.push('\n')
    end
    consume str

primitive ParseInput
  fun apply(lines: FileLines): Board =>
    let board = Board.create()

    var row: I64 = 0
    for line in lines do
      for (col, ch) in (consume line).array().pairs() do
        let level  = (ch - 48).usize() // ascii, will be between 0 and 9
        let coords = (row, col.i64())
        board.insert(coords, level)
      end
      row = row + 1
    end

    board


actor Main
  var path: String = "./input_sample.txt"

  new create(env: Env) =>
    let steps: USize = 100
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let board = ParseInput(file.lines())
        silver(env.out, steps, board)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, steps: USize, board: Board) =>
    var acc: USize = 0
    Debug("Before any steps:" + "\n" + PrintBoard(board))
    for s in Range[USize](0, steps) do
      acc = acc + step(board)
      if (s.mod(10)) == 9 then
        Debug("After step " + (s+1).string() + ":\n" + PrintBoard(board))
      end
    end
    out.print("Flashes: " + acc.string())

  fun tag step(board: Board): USize =>
    let deltas = [as (I64, I64):
      (0, -1); (1, -1); (1, 0); (1, 1); (0, 1); (-1, 1); (-1, 0); (-1, -1)
    ]

    var glows: USize = 0
    let zeroes = SetIs[(I64, I64)].create()
    let to_check = Array[(I64, I64)].create()

    // First, advance every octopus by 1
    for (coord, level) in board.pairs() do
      let new_level = (level + 1).mod(10)
      board.update(coord, new_level)

      // If this octopus would flash, then add it to `zeroes`, and add
      // all its neighbours (in all 8 directions)
      if new_level == 0 then
        glows = glows + 1
        zeroes.set(coord)
        for (dx, dy) in deltas.values() do
          to_check.push(
            (coord._1 + dx, coord._2 + dy)
          )
        end
      end
    end

    // Increase all octopus that were in the vecinity of glowing octopus by
    // one energy level. This list might contain duplicates if it was surrounded
    // by more than one flashing octopus
    while true do
      try
        let neigh_coord = to_check.shift()?
        // If this octopus flashed, skip it, it won't increase its level
        if zeroes.contains(neigh_coord) then
          continue
        end

        try
          // It might be a fake neighbour (outside board range), so wrap
          // in a try ... end
          let neigh_level = board(neigh_coord)?
          let new_level = (neigh_level + 1).mod(10)
          board.update(neigh_coord, new_level)

          if new_level == 0 then
            glows = glows + 1
            zeroes.set(neigh_coord)
            for (dx, dy) in deltas.values() do
              to_check.push(
                (neigh_coord._1 + dx, neigh_coord._2 + dy)
              )
            end
          end
        end
      else
        break
      end
    end

    glows
