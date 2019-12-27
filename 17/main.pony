use "files"
use "debug"
use "collections"

use "package:../07"
use eleven = "package:../11"
use thirteen = "package:../13"

type BoardPoint is (I64, I64)
type Scaffold is SetIs[BoardPoint]

primitive FileUtils
  fun load_board(env: Env, path: String, board: Scaffold)? =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File

    var x: I64 = 0
    var y : I64 = 0
    for line in file.lines() do
      for point in (consume line).runes() do
        if point == 35 then // #
          board.set((x, y))
        end
        x = x + 1
      end
      x = 0
      y = y - 1
    end

    file.dispose()

actor Main is eleven.FSM
  let _out: OutStream
  let _origin: BoardPoint = (0, 0)
  var _current_x: I64 = 0
  var _current_y: I64 = 0
  var _board_repr: String iso = recover String end
  let _board: Scaffold = SetIs[BoardPoint]

  new create(env: Env) =>
    _out = env.out
    try
      FileUtils.load_board(env, "./17/board.txt", _board)?
      process_board()
    else
      let code = thirteen.FileUtils.load_file(env, "./17/input.txt", [])
      let executor = eleven.ProgramActor.create(consume code, this)
      executor.turn_on()
    end

  be state_msg(i: I64) =>
    let code_point = i.u32()
    match code_point
    | 10 =>
      _current_x = 0
      _current_y = _current_y - 1
    else
      _current_x = _current_x + 1
      if code_point == 35 then // #
        let point = (_current_x, _current_y)
        _board.set(point)
      end
    end

    _board_repr.push_utf32(code_point)

  be subscribe(exe: Executor) =>
    // Stub, no input needed
    None

  be unsubscribe() =>
    _out.print("Program is done")
    let tmp = _board_repr = recover String end
    _out.print(consume tmp)
    process_board()

  be process_board() =>
    var alignment: U64 = 0
    var intersections: USize = 0
    for point in _board.values() do
      var is_intersection = true
      for n in _neighbors(point).values() do
        if not _board.contains(n) then
          is_intersection = false
        end
      end
      if is_intersection then
        intersections = intersections + 1
        let distance = _distance(point)
        Debug.out("Point (" + point._1.string() + "," + point._2.string() + ") at distance " + distance.string())
        alignment = alignment + distance
      end
    end
    _out.print("Got complete board")
    _out.print("Intersections: " + intersections.string())
    _out.print("Alignment: " + alignment.string())

  fun _distance(p: BoardPoint): U64 =>
    p._1.abs() * p._2.abs()

  fun _neighbors(p: BoardPoint): Array[BoardPoint] val =>
    let s = recover Array[BoardPoint] end
    s.push((p._1 + 1, p._2))
    s.push((p._1 - 1, p._2))
    s.push((p._1, p._2 + 1))
    s.push((p._1, p._2 - 1))
    consume s

