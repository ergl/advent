use "files"
use "collections"
use "itertools"

type WirePath is SetIs[Point]
type Point is (I64, I64)

primitive PointUtils
  fun taxicab(from: Point, to: Point): U64 =>
    (from._1 - to._1).abs() + (from._2 - to._2).abs()

  fun span(from: Point, to: Point): WirePath val =>
    if from._1 == to._1 then
      _span_x_axis(from, to)
    elseif from._2 == to._2 then
      _span_y_axis(from, to)
    else
      recover val WirePath.create() end
    end

  fun _span_x_axis(from: Point, to: Point): WirePath val =>
    let x = from._1
    var min_y = from._2.min(to._2)
    let max_y = from._2.max(to._2)

    let wpath: WirePath iso = recover iso WirePath.create((max_y - min_y).abs().usize()) end
    while min_y <= max_y do
      wpath.set((x, min_y))
      min_y = min_y + 1
    end

    recover val wpath end

  fun _span_y_axis(from: Point, to: Point): WirePath val =>
    let y = from._2
    var min_x = from._1.min(to._1)
    let max_x = from._1.max(to._1)

    let wpath: WirePath iso = recover iso WirePath.create((max_x - min_x).abs().usize()) end
    while min_x <= max_x do
      wpath.set((min_x, y))
      min_x = min_x + 1
    end

    recover val wpath end

  fun apply_op(point: Point, op: Op): Point =>
    match op
    | (Left, let n: I64) => (point._1 - n, point._2)
    | (Right, let n: I64) => (point._1 + n, point._2)
    | (Up, let n: I64) => (point._1, point._2 + n)
    | (Down, let n: I64) => (point._1, point._2 - n)
    else
      point
    end

  fun path_from_ops(from: Point, ops: Array[Op] val): WirePath val =>
    let wpath = recover iso WirePath.create() end

    var current_point = from
    for op in ops.values() do
      let dst = apply_op(current_point, op)
      let span_points = span(current_point, dst)
      for point in span_points.values() do
        wpath.set(point)
      end
      current_point = dst
    end

    recover val wpath end

primitive Left
primitive Right
primitive Up
primitive Down
type Direction is (Up | Down | Left | Right)
type Op is (Direction, I64)

primitive ParseUtil
  fun _parse_op(str: String): (Op | None) =>
    try
      let head = str(0)?
      let tail = str.substring(1)
      let op: Direction = match head
      | 82 => Right
      | 76 => Left
      | 85 => Up
      | 68 => Down
      else
        error
      end
      (op, tail.i64()?)
    else
      None
    end

  fun parse_ops(str: String): Array[Op] val =>
    recover val
      Iter[String](str.split_by(",").values())
        .filter_map[Op]({(op_str) => ParseUtil._parse_op(op_str)})
        .collect(Array[Op])
    end

primitive Util
  fun to_string(op: Op): String =>
    let str = match op._1
    | Left => "L"
    | Right => "R"
    | Up => "U"
    | Down => "D"
    end
    str.add(op._2.string())

  fun point_to_string(p: Point): String =>
    "(".add(p._1.string()).add(",").add(p._2.string()).add(")")

actor Main
  var path: String = "./3/input.txt"
  let example_1: (String, String) = (
    "R75,D30,R83,U83,L12,D49,R71,U7,L72",
    "U62,R66,U55,R34,D71,R55,D58,R83"
  )

  let example_2: (String, String) = (
    "R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
    "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7"
  )

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File do

      let origin: Point = (0, 0)
      let input = Iter[String](file.lines())
                      .map[WirePath val]({(line) => PointUtils.path_from_ops(origin, ParseUtil.parse_ops(line))})
                      .collect(Array[WirePath val](2))

      let first = input(0)?.clone()
      let second = input(1)?.clone()
      first.intersect(second)
      first.unset(origin)

      var min_distance = U64.max_value()
      for point in first.values() do
        min_distance = min_distance.min(PointUtils.taxicab(origin, point))
      end

      env.out.print(min_distance.string())
    end
    else
      env.out.print("Couldn't open ".add(path))
    end
