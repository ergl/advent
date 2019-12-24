use "collections"
use "debug"

use "package:../07"
use "package:../graph"
use eleven = "package:../11"

primitive North fun string(): String => "North"
primitive South fun string(): String => "South"
primitive East fun string(): String => "East"
primitive West fun string(): String => "West"
type Move is (North | East | South | West)

primitive Wall
primitive Ok
primitive OxygenFound
type MoveStatus is (Wall | Ok | OxygenFound)

primitive ResetToCandidate
primitive ExploreNeighbours
primitive MovingToCandidate
type DroidState is (ExploreNeighbours | ResetToCandidate | MovingToCandidate)

primitive _Utils
  fun move_to_int(m: Move): I64 =>
    match m
    | North => 1
    | South => 2
    | West => 3
    | East => 4
    end

  fun int_to_status(i: I64): MoveStatus =>
    match i
    | 1 => Ok
    | 2 => OxygenFound
    else Wall end

  fun opposite_move(m: Move): Move =>
    match m
    | North => South
    | South => North
    | East => West
    | West => East
    end

class val PositionWeight is (Comparable[PositionWeight])
  let pos: RoomPosition
  let weight: U64

  new val create(pos': RoomPosition, weight': U64) =>
    pos = pos'
    weight = weight'

  fun lt(that: PositionWeight): Bool =>
    match weight.compare(that.weight)
    | Less => true
    | Greater => false
    | Equal => pos.x < that.pos.x
    end

class val RoomPosition is (Comparable[RoomPosition val] & Hashable)
  let x: I64
  let y: I64

  new val create(x': I64, y': I64) =>
    x = x'
    y = y'

  fun apply(move: Move): RoomPosition =>
    match move
    | North => RoomPosition(x, y + 1)
    | South => RoomPosition(x, y - 1)
    | East => RoomPosition(x + 1 , y)
    | West => RoomPosition(x - 1, y)
    end

  fun to_move(that: RoomPosition): Move? =>
    if (x == (that.x - 1)) and (y == that.y) then
      East
    elseif (x == (that.x + 1)) and (y == that.y) then
      West
    elseif (x == that.x) and (y == (that.y - 1)) then
      North
    elseif (x == that.x) and (y == (that.y + 1)) then
      South
    else
      error
    end

  fun lt(that: RoomPosition): Bool =>
    match x.compare(that.x)
    | Less => true
    | Greater => false
    | Equal => y < that.y
    end

  fun eq(that: RoomPosition): Bool =>
    (x == that.x) and (y == that.y)

  fun hash(): USize =>
    let x_hash = x.hash()
    let y_hash = y.hash()
    let tmp = y_hash + 0x9e3779b9 + (x_hash << 6) + (x_hash >> 2)
    x_hash xor tmp

  fun string(): String =>
    "(".add(x.string()).add(",").add(y.string()).add(")")

actor DroidController is eleven.FSM
  let _out: OutStream
  embed _origin: RoomPosition = RoomPosition.create(0, 0)
  embed _graph: Graph[RoomPosition, HashEq[RoomPosition]]
  var _state: DroidState = ExploreNeighbours
  var _oxygen_point: RoomPosition = _origin // Dummy, don't do optional

  var _executor: (Executor | None) = None
  var _current_position: RoomPosition
  embed _remaining_moves: Array[Move] = Array[Move].create(4)
  var _last_move: Move = North // Dummy, don't do optional

  embed _weights: HashMap[RoomPosition, U64, HashEq[RoomPosition]]
  embed _next_candidates: MaxHeap[PositionWeight]
  embed _candidates: HashSet[RoomPosition, HashEq[RoomPosition]]

  new create(out: OutStream) =>
    _out = out
    _current_position = _origin

    _weights = HashMap[RoomPosition, U64, HashEq[RoomPosition]]
    _weights.insert(_current_position, 0)

    _next_candidates = MaxHeap[PositionWeight].create(4)
    _candidates = HashSet[RoomPosition, HashEq[RoomPosition]]

    _graph = Graph[RoomPosition, HashEq[RoomPosition]]
    _graph.add_vertex(_current_position)

  be subscribe(exe: Executor) =>
    _executor = exe
    _calculate_neighbor_moves()
    _send_next_move()
    _state = ExploreNeighbours

  be unsubscribe() => _executor = None

  fun ref _calculate_neighbor_moves() =>
    _remaining_moves.clear()
    _remaining_moves.push(North)
    _remaining_moves.push(South)
    _remaining_moves.push(West)
    _remaining_moves.push(East)

  fun ref _calculate_candidate_path() =>
    _remaining_moves.clear()
    try
      let next_candidate = _next_candidates.pop()?.pos
      _candidates.unset(next_candidate)

      Debug.out(_current_position.string().add(" -> ").add(next_candidate.string()))
      let path = _graph.path(_current_position, next_candidate)
      if path.size() == 0 then
        Debug.err("WARNING: No path from ".add(_current_position.string()).add(" to ").add(next_candidate.string()))
        _quit()
      end

      var path_edge = _current_position
      for node in path.values() do
        try
          let move = path_edge.to_move(node)?
          _remaining_moves.push(move)
          path_edge = node
        else
          Debug.err("WARNING: Wrong path contains non-neighbor from ".add(path_edge.string()).add(" to ").add(node.string()))
          _quit()
        end
      end
    else
      _part_two()
      _quit()
    end

  fun ref _part_two() =>
    match _graph.farthest_point(_oxygen_point)
    | (let point: RoomPosition, let distance: USize) =>
      _out.print("Point farthest apart from oxygen is "
                  .add(point.string())
                  .add(", ")
                  .add(distance.string())
                  .add(" steps away"))
    end

  fun ref _update_neighbor_info() =>
    let position = _current_position.apply(_last_move)
    _graph.add_vertex(position)
    _graph.add_edge(_current_position, position)

    let old_score = _weights.get_or_else(_current_position, U64.max_value())
    let new_score = try old_score +? 1 else U64.max_value() end
    if new_score < _weights.get_or_else(position, U64.max_value()) then
      _weights.insert(position, new_score)
      if not _candidates.contains(position) then
        _next_candidates.push(PositionWeight(position, new_score))
        _candidates.set(position)
      end
    end

  fun ref _send_next_move() =>
    try
      var next_move = _remaining_moves.shift()?
      _last_move = next_move
      _send_move(next_move)
    end

  fun _send_move(m: Move) =>
    try
      let exe = _executor as Executor
      exe.input(_Utils.move_to_int(m))
    end

  fun ref _handle_explore(response: MoveStatus) =>
    match response
    | Wall => _move_to_neighbor_or_candidate()
    else
      _update_neighbor_info()
      _send_move(_Utils.opposite_move(_last_move))
      _state = ResetToCandidate

      if response is OxygenFound then
        let position = _current_position.apply(_last_move)
        let path_size = _graph.path(_origin, position).size()
        _oxygen_point = position
        _out.print("Found oxygen at "
                    .add(position.string()
                    .add(", ")
                    .add(path_size.string()).add(" steps from origin")))
      end
    end

  fun ref _move_to_neighbor_or_candidate() =>
    _state = if _remaining_moves.size() != 0 then
      ExploreNeighbours
    else
      _calculate_candidate_path()
      MovingToCandidate
    end
    _send_next_move()

  fun ref _move_to_candidate_or_neighbor() =>
    _current_position = _current_position.apply(_last_move)
    _state = if _remaining_moves.size() != 0 then
      MovingToCandidate
    else
      _calculate_neighbor_moves()
      ExploreNeighbours
    end
    _send_next_move()

  be state_msg(msg: I64) =>
    match _state
    | ExploreNeighbours => _handle_explore(_Utils.int_to_status(msg))
    | ResetToCandidate => _move_to_neighbor_or_candidate()
    | MovingToCandidate => _move_to_candidate_or_neighbor()
    end

  fun _quit() =>
    match _executor
    | let e: Executor => e.turn_off()
    end
