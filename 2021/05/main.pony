use "files"
use "collections"
use "itertools"

primitive Utils
  fun insert_path_points(
    start: (U32, U32),
    ends: (U32, U32),
    index: MapIs[(U32, U32), U32],
    include_diagonal: Bool = false)
  =>
    (let x0, let y0) = start
    (let x1, let y1) = ends

    if x0 == x1 then
      // Vertical
      var curr_y = y0.min(y1)
      while curr_y <= y0.max(y1) do
        let point = (x0, curr_y)
        index.insert(point, 1 + index.get_or_else(point, 0))
        curr_y = curr_y + 1
      end
    elseif y0 == y1 then
      // Horizontal
      var curr_x = x0.min(x1)
      while curr_x <= x0.max(x1) do
        let point = (curr_x, y0)
        index.insert(point, 1 + index.get_or_else(point, 0))
        curr_x = curr_x + 1
      end
    elseif
      include_diagonal and
      ((y1.i32() - y0.i32()).abs() ==
      (x1.i32() - x0.i32()).abs())
    then
      // 45 degrees
      (
        (var start_x, var start_y),
        (let end_x, let end_y)
      ) =
        if x0 < x1 then
          ((x0, y0), (x1, y1))
        else
          ((x1, y1), (x0, y0))
        end

      while start_x <= end_x do
        let point = (start_x, start_y)
        index.insert(point, 1 + index.get_or_else(point, 0))
        start_x = start_x + 1
        start_y =
          if end_y > start_y then // Going up
            start_y + 1
          else
            start_y - 1
          end
      end
    end

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let board =
          Iter[String](file.lines())
            // Parse each line
            .map[((U32, U32), (U32,U32))]({(line)? =>
              let parts = line.split_by(" -> ", 2)
              let begin_coord = parts(0)?.split(",")
              let end_coord = parts(1)?.split(",")  
              let starts_at = (
                begin_coord(0)?.read_int[U32](where base = 10)?._1,
                begin_coord(1)?.read_int[U32](where base = 10)?._1
              )
              let ends_at = (
                end_coord(0)?.read_int[U32](where base = 10)?._1,
                end_coord(1)?.read_int[U32](where base = 10)?._1
              )
              (starts_at, ends_at)
            })
            .collect(Array[((U32, U32), (U32,U32))])

          let silver = solve_paths(board, {(acc, init_and_end) =>
            Utils.insert_path_points(
                init_and_end._1,
                init_and_end._2,
                acc
            )
            acc
          })
          let gold = solve_paths(board, {(acc, init_and_end) =>
            Utils.insert_path_points(
                init_and_end._1,
                init_and_end._2,
                acc,
                true
            )
            acc
          })
          env.out.print("Silver: " + silver.string())
          env.out.print("Gold: " + gold.string())
      end
    else
      env.err.print("Error")
    end

  fun tag solve_paths(
    coordinates: Array[((U32, U32), (U32,U32))] box,
    fold_fun: {(MapIs[(U32, U32), U32], ((U32, U32), (U32, U32))): MapIs[(U32, U32), U32]})
    : U32
  =>
    let index =
      Iter[((U32, U32), (U32,U32))](coordinates.values())
      .fold[MapIs[(U32, U32), U32]](
        MapIs[(U32, U32), U32],
        fold_fun
      )

    var overlaps: U32 = 0
    for frequencies in index.values() do
      if frequencies >= 2 then
        overlaps = overlaps + 1
      end
    end
    overlaps
