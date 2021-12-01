use "package:../07"
use "collections"

primitive Black
  fun string(): String => "⬛️"
primitive White
  fun string(): String => "⬜️"

type Color is (Black | White)

primitive Left
  fun string(): String => "Left"
primitive Right
  fun string(): String => "Right"

type Turn is (Left | Right)

primitive North
primitive South
primitive East
primitive West
type Direction is (North | East | South | West)

primitive Init
primitive Painting
type RobotState is (Init | Painting)

type HullPos is (I64, I64)

primitive ParseUtils
  fun c_from_int(i: I64): Color? =>
    match i
    | 0 => Black
    | 1 => White
    else error end

  fun c_to_int(c: Color): I64 =>
    match c
    | Black => 0
    | White => 1
    end

  fun t_from_int(i: I64): Turn? =>
    match i
    | 0 => Left
    | 1 => Right
    else error end

actor Robot is FSM
  let _out: OutStream
  var _position: HullPos
  var _direction: Direction
  var _state: RobotState
  let _hull: MapIs[HullPos, Color]
  let _visited: SetIs[HullPos]
  var _executor: (Executor | None)

  var _min_x: I64 = 0
  var _max_x: I64 = 0
  var _min_y: I64 = 0
  var _max_y: I64 = 0

  new create(out: OutStream) =>
    _out = out
    _position = (0, 0)
    _state = Init
    _direction = North
    _hull = MapIs[HullPos, Color].create()
    _hull.insert(_position, White)
    _visited = SetIs[HullPos].create()
    _executor = None

  be subscribe(exe: Executor) =>
    _executor = exe
    _send_color()

  be unsubscribe() =>
    let visited = _visited.size()
    _out.print("Visited ".add(visited.string()).add(" positions"))
    try _show_visited()? end

  fun box _send_color() =>
    match _executor
    | None => None
    | let exe: ProgramActor =>
      let current_color = _hull.get_or_else(_position, Black)
      exe.input(ParseUtils.c_to_int(current_color))
    end

  be state_msg(elt: I64) =>
    match _state
    | Init =>
      try
        state_paint(ParseUtils.c_from_int(elt)?)
        _state = Painting
      end
    | Painting =>
      try
        state_move(ParseUtils.t_from_int(elt)?)
        _state = Init
      end
    end

  fun ref state_paint(color: Color) =>
    _hull.insert(_position, color)
    _visited.set(_position)

  fun ref state_move(turn: Turn) =>
    match turn
    | Left => _turn_left()
    | Right => _turn_right()
    end
    _move()
    _send_color()

  fun ref _turn_left() =>
    _direction = match _direction
    | North => West
    | East => North
    | South => East
    | West => South
    end

  fun ref _turn_right() =>
    _direction = match _direction
    | North => East
    | East => South
    | South => West
    | West => North
    end

  fun ref _move() =>
    _position = match _direction
    | North => (_position._1, _position._2 + 1)
    | East => (_position._1 - 1, _position._2)
    | South => (_position._1, _position._2 - 1)
    | West => (_position._1 + 1, _position._2)
    end

    _min_x = _min_x.min(_position._1)
    _max_x = _max_x.max(_position._1)

    _min_y = _min_y.min(_position._2)
    _max_y = _max_y.max(_position._2)

  fun box _show_visited()? =>
    let width = (_max_x - _min_x).abs().usize()
    let height = (_max_y - _min_y).abs().usize()
    let layer: Array[Array[Color]] = Array[Array[Color]].create()
    for i in Range.create(0, height + 1) do
      layer.push(Array[Color].init(Black, width + 1))
    end

    for point in _visited.values() do
      let c = _hull.get_or_else(point, Black)
      let x = point._1.neg().usize()
      let y = point._2.neg().usize()
      layer(y)?(x)? = c
    end

    let str = String.create()
    for y in Range.create(0, height + 1) do
      let row = layer(y)?
      for x in Range.create(0, width + 1) do
        str.concat(row(x)?.string().values())
      end
      str.push('\n')
    end
    str

    _out.print(str.clone())
