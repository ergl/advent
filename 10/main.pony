use "collections"
use "files"
use "itertools"

type Point is (I64, I64)
type Angle is F64
type Distance is F64

primitive Utils
  fun slope(source: Point, dst: Point): Angle =>
    let trans_x = (dst._1 - source._1).f64()
    let trans_y = (dst._2 - source._2).f64()
    trans_x.atan2(trans_y)

  fun points_equal(left: Point, right: Point): Bool =>
    (left._1 == right._1) and (left._2 == right._2)

  fun distance(src: Point, dst: Point): Distance =>
    let x_diff = (dst._1 - src._1).abs()
    let y_diff = (dst._2 - src._2).abs()
    let sum = (x_diff * x_diff) + (y_diff * y_diff)
    sum.f64().sqrt()

class val SortedEntry is Comparable[SortedEntry]
  let _distance: Distance
  let point: Point

  new val create(distance: Distance, point': Point) =>
    _distance = distance
    point = point'

  fun lt(that: SortedEntry): Bool =>
    _distance < that._distance

class ref SortedField
  let _mem: MapIs[Angle, Array[SortedEntry val]] = MapIs[Angle, Array[SortedEntry val]].create()
  let _sorter: Sort[Array[SortedEntry val], SortedEntry] = Sort[Array[SortedEntry val], SortedEntry].create()

  fun ref put(angle: Angle, point: Point, distance: Distance) =>
    let queue = _mem.get_or_else(angle, [])
    queue.push(SortedEntry.create(distance, point))
    _mem(angle) = queue

  fun ref get_nearest(angle: Angle): (Point | None) =>
    let queue = _mem.get_or_else(angle, [])
    let queue_sorted = _sorter(queue)
    let head = try queue_sorted.shift()? else None end
    _mem(angle) = queue_sorted
    match head
    | let entry: SortedEntry => entry.point
    end

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

  fun tag part_1(asteroids: Array[Point] box): (Point, U64) =>
    var max_visibility: U64 = 0
    var max_point: Point = (0, 0)
    try
      for i in Range.create(0, asteroids.size()) do
        let src = asteroids(i)?
        let uniques = SetIs[Angle].create()
        for j in Range.create(0, asteroids.size()) do
          if i != j then
            uniques.set(Utils.slope(src, asteroids(j)?))
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

  fun tag part_2(origin: Point, asteroids: Array[Point] box): Point =>
    let angles = SetIs[Angle].create()
    let field: SortedField ref = SortedField.create()
    for dst in asteroids.values() do
      if not Utils.points_equal(origin, dst) then
        let angle = Utils.slope(origin, dst)
        field.put(angle, dst, Utils.distance(origin, dst))
        angles.set(angle)
      end
    end

    var sorted_angles = Iter[Angle](angles.values()).collect(Array[Angle])
    sorted_angles = Sort[Array[Angle], Angle](sorted_angles)
    sorted_angles.reverse_in_place()

    var counter: U64 = 1
    var target_asteroid: Point = (0, 0)
    var cycle = Iter[Angle](sorted_angles.values()).cycle()
    while cycle.has_next() do
      let angle = try cycle.next()? else /* unreachable */ 0 end
      match field.get_nearest(angle)
      | let ast: Point =>
        if counter == 200 then
          target_asteroid = ast
          break
        end
        counter = counter + 1
      end
    end

    target_asteroid

  new create(env: Env) =>
    let asteroids = Array[Point].create()
    FileUtils.load_grid(env, "./10/input.txt", asteroids)
    (let max_point, let max_visibility) = part_1(asteroids)
    env.out.print("Max point is ".add(p_to_string(max_point)))
    env.out.print("Max visibility is ".add(max_visibility.string()))

    let target = part_2(max_point, asteroids)
    let answer = (target._1 * 100) + target._2
    env.out.print("200th asteroid is ".add(p_to_string(target)).add(" with answer ").add(answer.string()))
