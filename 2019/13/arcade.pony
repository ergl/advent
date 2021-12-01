use "package:../07"
use eleven = "package:../11"
use "collections"
use "itertools"

primitive Empty
  fun string(): String => "⬜️"
primitive Wall
  fun string(): String => "❌"
primitive Block
  fun string(): String => "⬛️"
primitive Paddle
  fun string(): String => "➖"
primitive Ball
  fun string(): String => "🏀"

type Tile is (Empty | Wall | Block | Paddle | Ball)

primitive OutputX
primitive OutputY
primitive OutputTile
primitive ScoreY
primitive OutputScore
type ArcadeOutputState is (OutputX | OutputY | OutputTile | ScoreY | OutputScore)

type WindowPos is (U64, U64)

primitive ParseUtils
  fun tile_from_int(i: I64): Tile? =>
    match i
    | 0 => Empty
    | 1 => Wall
    | 2 => Block
    | 3 => Paddle
    | 4 => Ball
    else error end

actor Arcade is eleven.FSM
  let _out: OutStream
  let _window: MapIs[WindowPos, Tile]
  var _executor: (Executor | None)
  var _state: ArcadeOutputState

  var _tmp_x: U64 = 0
  var _tmp_y: U64 = 0

  var _max_x: U64 = 0
  var _max_y: U64 = 0

  var _score: I64 = 0

  var _paddle_x: (U64 | None) = 0
  var _curr_ball_pos: (WindowPos | None) = None
  var _prev_ball_pos: (WindowPos | None) = None

  new create(out: OutStream) =>
    _out = out
    _state = OutputX
    _window = MapIs[WindowPos, Tile].create()
    _executor = None

  be subscribe(exe: Executor) =>
    _executor = exe

  be unsubscribe() =>
    _executor = None
    _out.print("Total tiles: ".add(_window.size().string()))
    _out.print("Of which ".add(count_blocks().string()).add(" are blocks"))
    _out.print("Total score: ".add(_score.string()))

  fun box count_blocks(): U64 =>
    Iter[Tile](_window.values())
      .filter({(tile) => tile is Block})
      .count().u64()

  be state_msg(elt: I64) =>
    match _state
    | OutputX =>
      let tmp = elt.u64()
      match tmp
      | -1 => _state = ScoreY
      else
        _tmp_x = tmp
        _max_x = _max_x.max(_tmp_x)
        _state = OutputY
      end
    | OutputY =>
      _tmp_y = elt.u64()
      _max_y = _max_y.max(_tmp_y)
      _state = OutputTile
    | ScoreY =>
        _state = OutputScore
    | OutputScore =>
      _score = elt
      _out.print("Total score: ".add(_score.string()))
      _state = OutputX
    | OutputTile =>
      try
        let tile = ParseUtils.tile_from_int(elt)?
        match tile
        | Ball =>
          _curr_ball_pos = (_tmp_x, _tmp_y)
          _move_paddle()
        | Paddle => _paddle_x = _tmp_x
        end
        _window.insert((_tmp_x, _tmp_y), tile)
        // _redraw()?
      end
      _state = OutputX
    end

  fun ref _move_paddle() =>
    match (_paddle_x, _curr_ball_pos)
    | (let x: U64, let pos: WindowPos) =>
      let move: I64 = if x > pos._1 then
        -1
      elseif x < pos._1 then
        1
      else
        match _prev_ball_pos
        | let prev_pos: WindowPos =>
          let ball_up = prev_pos._2 < pos._2
          if ball_up then
            0
          else
            if prev_pos._1 < prev_pos._1 then
              1
            else
             -1
            end
          end
        else 0 end
      end
      match _executor
      | let s: Executor => s.input(move)
      end
      _prev_ball_pos = _curr_ball_pos
    end

  // fun _redraw()? =>
  //   let width = _max_x.usize()
  //   let height = _max_y.usize()
  //   let layer: Array[Array[Tile]] = Array[Array[Tile]].create()
  //   for i in Range.create(0, height + 1) do
  //     layer.push(Array[Tile].init(Empty, width + 1))
  //   end

  //   for (pos, tile) in _window.pairs() do
  //     let x = pos._1.usize()
  //     let y = pos._2.usize()
  //     layer(y)?(x)? = tile
  //   end

  //   let str = String.create()
  //   for y in Range.create(0, height + 1) do
  //     let row = layer(y)?
  //     for x in Range.create(0, width + 1) do
  //       str.append(row(x)?.string())
  //     end
  //     str.push('\n')
  //   end
  //   str.push('\n')
  //   str.append("Score: ".add(_score.string()))

  //   _out.print(str.clone())

