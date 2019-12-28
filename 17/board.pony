use "files"
use "collections"

use "package:../graph"
use fifteen = "package:../15"

type Pos is fifteen.RoomPosition

class Board
  embed _graph: Graph[Pos, HashEq[Pos]] = Graph[Pos, HashEq[Pos]]
  var robot_pos: Pos = Pos(0, 0) // Dummy
  var maze_end: Pos = Pos(0, 0) // Dummy

  new create(env: Env, path: String) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
     with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
     do
        var x: I64 = 0
        var y : I64 = 0
        for line in file.lines() do
          for rune in (consume line).runes() do
            x = x + 1
            if rune == '.' then
              // No more types of runes other than # and robot
              continue
            end

            let pos = Pos(x - 1, y) // Adjust x
            _graph.add_vertex(pos)
            if _is_robot(rune) then
              robot_pos = pos
            end

            for n in _neighbors(pos).values() do
              if _graph.is_vertex(n) then
                _graph.add_edge(pos, n)
              end
            end
          end
          x = 0
          y = y - 1
        end
      end
    end

    try maze_end = _maze_end() as Pos end

  fun _neighbors(pos: Pos): Array[Pos] val =>
    let r = recover Array[Pos] end
    r.push(Pos(pos.x + 1, pos.y))
    r.push(Pos(pos.x - 1, pos.y))
    r.push(Pos(pos.x, pos.y + 1))
    r.push(Pos(pos.x, pos.y - 1))
    consume r

  fun _maze_end(): (Pos | None) =>
    for v in _graph.vertices() do
      if (_graph.degree(v) == 1) and (v != robot_pos) then
        return v
      end
    end

  fun _is_robot(char: U32): Bool =>
    (char == '^') or
    (char == 'v') or
    (char == '>') or
    (char == '<')

  // TODO(borja): Go back and do simpler path, just keep going straight until we can't anymore
  fun ref solve_path(): Array[Pos] val =>
    GraphUtils.euler_path[Pos, HashEq[Pos]](robot_pos, _graph)

  // fun _load_intcode(): Array[I64] val? =>
  //   let file = OpenFile(FilePath(_auth, _intcode_path, _caps)?) as File
  //   let program = recover Array[I64] end
  //   let commands = file.read_string(file.size()).split_by(",")
  //   for n in commands.values() do
  //     program.push(try n.i64()? else 0 end)
  //   end
  //   file.dispose()
  //   consume program