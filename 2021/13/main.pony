use "files"
use "collections"

use "debug"

primitive Up
primitive Left
type Direction is (Up | Left)
type Moves is Array[(Direction, I64)]

class Sheet
  embed _repr: MapIs[(I64, I64), U32] = _repr.create()
  embed _index_x: MapIs[I64, SetIs[I64]] = _index_x.create()
  embed _index_y: MapIs[I64, SetIs[I64]] = _index_y.create()

  var last_row: I64 = 0
  var last_col: I64 = 0

  new create() => None

  fun ref insert(point: (I64, I64)) =>
    _repr.insert(point, 1)
    _insert_index(point)

  fun ref _insert_index(point: (I64, I64)) =>
    (let x, let y) = point
    if not _index_x.contains(x) then
      _index_x(x) = SetIs[I64]
    end
    try _index_x(x)?.set(y) end

    if not _index_y.contains(y) then
      _index_y(y) = SetIs[I64]
    end
    try _index_y(y)?.set(x) end

  fun ref _clear_index(point: (I64, I64)) =>
    (let x, let y) = point
    try
      _index_x(x)?.unset(y)
      _index_y(y)?.unset(x)
    end

  fun count_points(): USize =>
    var visible: USize = 0
    for sum in _repr.values() do
      if sum >= 1 then
        visible = visible + 1
      end
    end
    visible

  // Clone, otherwise we'll update the index while we iterate over it - a no-no
  fun points_at_x(x: I64): SetIs[I64] box ? => _index_x(x)?.clone()
  fun points_at_y(y: I64): SetIs[I64] box ? => _index_y(y)?.clone()

  fun ref move_point_up(point: (I64, I64), delta: I64) =>
    (let x, let y) = point
    let new_y = y - delta

    _clear_index(point)

    try
      // Remove the old point entirely, but check how many points were there
      (_, let old_count) = _repr.remove(point)?
      // Now add those points to the new coordinate
      _repr.upsert(
        (x, new_y),
        old_count,
        {(current, provided) => current + provided}
      )

      _insert_index((x, new_y))
    end

  fun ref move_point_left(point: (I64, I64), delta: I64) =>
    (let x, let y) = point
    let new_x = x - delta

    _clear_index(point)

    try
      // Remove the old point entirely, but check how many points were there
      (_, let old_count) = _repr.remove(point)?
      // Now add those points to the new coordinate
      _repr.upsert(
        (new_x, y),
        old_count,
        {(current, provided) => current + provided}
      )

      _insert_index((new_x, y))
    end

  fun string(): String iso^ =>
    let str = recover String.create((last_row * last_col).usize()) end
    for y in Range[I64](0, last_row + 1) do
      for x in Range[I64](0, last_col + 1) do
        let point_count = _repr.get_or_else((x, y), 0)
        str.push(if point_count > 0 then '#' else '.' end)
      end
      str.push('\n')
    end
    consume str

  fun clone(): Sheet ref^ =>
    let that = Sheet.create()
    that.last_row = last_row
    that.last_col = last_col
    for (point, sum) in _repr.pairs() do
      that._repr.insert(point, sum)
      that._insert_index(point)
    end
    that

primitive ParseInput
  fun apply(lines: FileLines): (Sheet, Moves) ? =>
    let sheet = Sheet.create()
    let moves = Moves.create()

    var parse_directions = false
    for line in lines do
      if (not parse_directions) and (line.size() == 0) then
        // Last coord, space, then moves start
        parse_directions = true
        continue
      elseif not parse_directions then
        let points = (consume line).split(",", 2)
        (let x, _) = points(0)?.read_int[I64](where base = 10)?
        (let y, _) = points(1)?.read_int[I64](where base = 10)?
        if x > sheet.last_col then sheet.last_col = x end
        if y > sheet.last_row then sheet.last_row = y end
        sheet.insert((x, y))
      else
        var fold = (consume line).split(" ")
        fold = fold(fold.size() - 1)?.split("=", 2)
        let direction = fold(0)?
        (let coordinate, _) = fold(1)?.read_int[I64](where base = 10)?
        match direction
        | "x" => moves.push((Left, coordinate))
        | "y" => moves.push((Up, coordinate))
        end
      end
    end

    (sheet, moves)

actor Main
  let path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        (let sheet, let moves) = ParseInput(file.lines())?
        silver(env.out, sheet.clone(), moves)
        gold(env.out, sheet, moves)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, sheet: Sheet, moves: Moves box) =>
    try
      match moves(0)?
      | (Up, let at: I64) =>
        for y in Range[I64](at+1, sheet.last_row + 1) do
          let delta = 2 * (y - at)
          try
            let points = sheet.points_at_y(y)?
            for x in points.values() do
              sheet.move_point_up((x, y), delta)
            end
          end
        end
        sheet.last_row = at
      | (Left, let at: I64) =>
        for x in Range[I64](at + 1, sheet.last_col + 1) do
          let delta = 2 * (x - at)
          try
            let points = sheet.points_at_x(x)?
            for y in points.values() do
              sheet.move_point_left((x, y), delta)
            end
          end
        end
        sheet.last_col = at
      end
    end
    out.print("Silver: Visible points: " + sheet.count_points().string())

  fun tag gold(out: OutStream, sheet: Sheet, moves: Moves box) =>  
    for move in moves.values() do
      match move
      | (Up, let at: I64) =>
        for y in Range[I64](at+1, sheet.last_row + 1) do
          let delta = 2 * (y - at)
          try
            let points = sheet.points_at_y(y)?
            for x in points.values() do
              sheet.move_point_up((x, y), delta)
            end
          end
        end
        sheet.last_row = at
      | (Left, let at: I64) =>
        for x in Range[I64](at + 1, sheet.last_col + 1) do
          let delta = 2 * (x - at)
          try
            let points = sheet.points_at_x(x)?
            for y in points.values() do
              sheet.move_point_left((x, y), delta)
            end
          end
        end
        sheet.last_col = at
      end
    end
    out.print("Gold:\n" + sheet.string())
