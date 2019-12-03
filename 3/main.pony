use "files"
use "collections"
use "itertools"

type WirePath is SetIs[Point]
type Steps is MapIs[Point, U64]
type WireInfo is (WirePath val, Steps val)

type Point is (I64, I64)

primitive PointUtils
  fun taxicab(from: Point, to: Point): U64 =>
    (from._1 - to._1).abs() + (from._2 - to._2).abs()

  fun set_span(from: Point, to: Point, init_steps: U64,
               wpath: WirePath, steps: Steps): U64 =>

    if from._1 == to._1 then
      _set_span_x_axis(from, to, init_steps, wpath, steps)
    else
      _set_span_y_axis(from, to, init_steps, wpath, steps)
    end

  fun _set_span_x_axis(from: Point, to: Point, init_steps: U64,
                       wpath: WirePath, steps: Steps): U64 =>

    let x = from._1
    var min_y = from._2.min(to._2)
    let max_y = from._2.max(to._2)

    var max_steps = init_steps
    while min_y <= max_y do
      let p: Point = (x, min_y)
      let p_steps = init_steps + taxicab(from, p)
      wpath.set(p)
      steps.update(p, p_steps)
      max_steps = max_steps.max(p_steps)
      min_y = min_y + 1
    end

    max_steps

  fun _set_span_y_axis(from: Point, to: Point, init_steps: U64,
                       wpath: WirePath, steps: Steps): U64 =>

    let y = from._2
    var min_x = from._1.min(to._1)
    let max_x = from._1.max(to._1)

    var max_steps = init_steps
    while min_x <= max_x do
      let p: Point = (min_x, y)
      let p_steps = init_steps + taxicab(from, p)
      wpath.set(p)
      steps.update(p, p_steps)
      max_steps = max_steps.max(p_steps)
      min_x = min_x + 1
    end

    max_steps

  fun apply_op(point: Point, op: Op): Point =>
    match op
    | (Left, let n: I64) => (point._1 - n, point._2)
    | (Right, let n: I64) => (point._1 + n, point._2)
    | (Up, let n: I64) => (point._1, point._2 + n)
    | (Down, let n: I64) => (point._1, point._2 - n)
    else
      point
    end

  fun fill_path_from_ops(from: Point, ops: Array[Op] val, wpath: WirePath, steps: Steps)=>
    var current_steps: U64 = 0
    var current_point = from

    for op in ops.values() do
      let dst = apply_op(current_point, op)
      let span_max = set_span(current_point, dst, current_steps, wpath, steps)
      current_steps = current_steps.max(span_max)
      current_point = dst
    end

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
      let input_ops = Iter[String](file.lines())
                          .map[Array[Op] val]({(line) => ParseUtil.parse_ops(line)})
                          .collect(Array[Array[Op] val](2))

      let first_wire = WirePath()
      let first_steps = Steps()
      PointUtils.fill_path_from_ops(origin, input_ops(0)?, first_wire, first_steps)

      let second_wire = WirePath()
      let second_steps = Steps()
      PointUtils.fill_path_from_ops(origin, input_ops(1)?, second_wire, second_steps)

      first_wire.intersect(second_wire)
      first_wire.unset(origin)

      var min_cost = U64.max_value()
      for point in first_wire.values() do
        let point_steps = first_steps(point)? + second_steps(point)?
        min_cost = min_cost.min(point_steps)
      end

      env.out.print(min_cost.string())
    end
    else
      env.out.print("Couldn't open ".add(path))
    end
