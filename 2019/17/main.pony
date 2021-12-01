use f = "package:../15"
use "itertools"

primitive Left fun string(): String => "L"
primitive Right fun string(): String => "R"
primitive Straight fun string(): String => "Straight"
type Move is (Straight | Left | Right, U8)
type Orientation is f.Move

primitive MoveUtils
  fun apply(pos: Pos, o: Orientation, other_pos: Pos): (Move, Orientation)? =>
    let direction = pos.to_move(other_pos)?
    (apply_move(o, direction), direction)

  fun string(m: Move): String =>
    m._1.string() + m._2.string()

  fun can_combine(l: Move, r: Move): Bool =>
    match (l._1, r._1)
    | (Left, Straight) => true
    | (Right, Straight) => true
    else false end

  fun apply_move(l: Orientation, r: Orientation): Move =>
    let d = match (l, r)
    | (f.North, f.East) => Right
    | (f.East, f.South) => Right
    | (f.South, f.West) => Right
    | (f.West, f.North) => Right

    | (f.North, f.West) => Left
    | (f.West, f.South) => Left
    | (f.South, f.East) => Left
    | (f.East, f.North) => Left
    else Straight end
    (d, 1)

actor Main
  new create(env: Env) =>
    let b = Board(env, "./17/board.txt")
    try
      let moves = Array[Move]
      var init_pos = b.robot_pos
      var init_orientation: Orientation = f.North
      for point in b.solve_path().values() do
        (let move, let orient) = MoveUtils(init_pos, init_orientation, point)?
        moves.push(move)
        init_pos = point
        init_orientation = orient
      end
      let combined = Array[Move]
      for m in moves.values() do
        if combined.size() == 0 then
          combined.push(m)
        else
          let last = combined.pop()?
          if MoveUtils.can_combine(last, m) then
            combined.push((last._1, last._2 + 1))
          else
            combined.push(last)
            combined.push(m)
          end
        end
      end
      let str = recover String.create() end
      for finally in combined.values() do
        str.append(MoveUtils.string(finally))
        str.push(',')
      end
      env.out.print(consume str)
    end
