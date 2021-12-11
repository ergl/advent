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
  var path: String = "./input.txt"

  new create(env: Env) =>
    let steps: USize = 100
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let board = ParseInput(file.lines())
        solve(env.out, steps, board)
      end
    else
      env.err.print("Error")
    end

  fun tag solve(out: OutStream, steps: USize, board: Board) =>
    let check_scratchpad = Array[(I64, I64)].create(board.size() / 2)
    let deltas = recover val
      [as (I64, I64):
        (0, -1); (1, -1); (1, 0); (1, 1); (0, 1); (-1, 1); (-1, 0); (-1, -1)
      ]
    end

    var acc: USize = 0
    var sync_step: (USize | None) = None

    Debug("Before any steps:" + "\n" + PrintBoard(board))
    var current_step: USize = 0
    while true do
      (let delta, let synchronized) = step(board, deltas, check_scratchpad.>clear())
      if synchronized and (sync_step is None) then
        sync_step = (current_step + 1)
        if current_step >= steps then
          break
        end
      end

      if current_step < steps then
        acc = acc + delta
        if (current_step.mod(10)) == 9 then
          Debug(
            "After step " + (current_step+1).string() + ":\n" +
            PrintBoard(board)
          )
        end
      end
      current_step = current_step + 1
    end

    out.print("Silver. Flashes after " + steps.string() + ": " + acc.string())
    match sync_step
    | None =>
        out.print("Gold. Error, no sync steps")
    | let s: USize =>
        out.print("Gold. First synchronized on step " + s.string())
    end

  fun tag step(
    board: Board,
    deltas: Array[(I64, I64)] val,
    to_check: Array[(I64, I64)])
    : (USize, Bool)
  =>

    var glows: USize = 0

    // First, advance every octopus by 1
    for (coord, level) in board.pairs() do
      let new_level = (level + 1).mod(10)
      board.update(coord, new_level)

      // If this octopus would flash, add all its neighbours
      // (in all 8 directions)
      if new_level == 0 then
        glows = glows + 1
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

        try
          // It might be a fake neighbour (outside board range), so wrap
          // in a try ... end
          let neigh_level = board(neigh_coord)?

          // If this octopus flashed, skip it, it won't increase its level
          if neigh_level == 0 then
            continue
          end

          let new_level = (neigh_level + 1).mod(10)
          board.update(neigh_coord, new_level)

          if new_level == 0 then
            glows = glows + 1
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

    var synchronized = false
    if glows == board.size() then
      synchronized = true
    end

    (glows, synchronized)
