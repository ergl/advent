use "collections"
use "files"
use "itertools"

type Point is (I64, I64)
type Angle is F64

primitive FileUtils
  fun load_grid(env: Env, path: String, points: Array[Point] ref) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      var y_coord: I64 = 0
      for line in file.lines() do
        let l_tmp: String ref = consume line
        Iter[U8].create(l_tmp.values())
                .enum()
                .map_stateful[None]({(elt)(points) =>
                  if elt._2 == 35 then // 35 = ascii(#)
                    points.push((elt._1.i64(), y_coord))
                  end
                })
                .run()
        y_coord = y_coord + 1
      end
      file.dispose()
    end


actor Main
  fun tag p_to_string(p: Point): String =>
    "(".add(p._1.string()).add(",").add(p._2.string()).add(")")

  fun tag slope(source: Point, dst: Point): Angle =>
    let trans_x = (dst._1 - source._1).f64()
    let trans_y = (dst._2 - source._2).f64()
    trans_x.atan2(trans_y)

  fun tag part_1(asteroids: Array[Point] box): (Point, U64) =>
    var max_visibility: U64 = 0
    var max_point: Point = (0, 0)
    try
      for i in Range.create(0, asteroids.size()) do
        let src = asteroids(i)?
        let uniques = SetIs[Angle].create()
        for j in Range.create(0, asteroids.size()) do
          if i != j then
            uniques.set(slope(src, asteroids(j)?))
          end
        end

        let visible = uniques.size().u64()
        if visible > max_visibility then
          max_visibility = visible
          max_point = src
        end
      end
    end

    (max_point, max_visibility)

  new create(env: Env) =>
    let asteroids = Array[Point].create()
    FileUtils.load_grid(env, "./10/input.txt", asteroids)
    (let max_point, let max_visibility) = part_1(asteroids)
    env.out.print("Max point is ".add(p_to_string(max_point)))
    env.out.print("Max visibility is ".add(max_visibility.string()))
