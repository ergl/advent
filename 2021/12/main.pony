use "../../common/graph"

use "files"
use "collections"

use "debug"

class val StringHash is HashFunction[String]
  new val create() => None
  fun hash(s: String): USize => s.hash()
  fun eq(left: String, right: String): Bool => left == right

type Cave is Graph[String, StringHash]

primitive ParseInput
  fun apply(lines: FileLines): Cave ? =>
    let cave = Cave.create()

    for line in lines do
      let points = (consume line).split("-", 2)
      let start_point = points(0)?
      let end_point = points(1)?
      cave.add_vertex(start_point)
      cave.add_vertex(end_point)
      cave.add_edge(start_point, end_point)
    end

    cave

class CavePath
  embed _path_so_far: Array[String] = _path_so_far.create()
  embed _visited: HashSet[String, StringHash] = _visited.create()

  new create() => None

  fun ref push(v: String) =>
    _path_so_far.push(v)
    if v.upper() != v then
      _visited.set(v)
    end

  fun contains(v: String): Bool =>
    _visited.contains(v)

  fun nodes(): Iterator[this->String] =>
    _path_so_far.values()

  fun last(): String ? =>
    _path_so_far(_path_so_far.size() - 1)?

  fun clone(): CavePath ref^ =>
    let ret = CavePath.create()
    for n in _path_so_far.values() do
      ret.push(n)
    end
    ret

actor Main
  let i_path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, i_path)) as File
      do
        let cave = ParseInput(file.lines())?
        silver(env.out, cave)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, cave: Cave box) =>
    let queue = Array[CavePath].create()
    let all_paths = Array[CavePath].create()

    var path = CavePath.create()
    path.push("start")
    queue.push(path.clone())

    try
      while true do
        path = queue.shift()?
        let last = path.last()?
        if last == "end" then
          all_paths.push(path.clone())
          continue
        end

        for n in cave.neighbors(last) do
          Debug("Neighbour of " + last + ": " + n)
          if not path.contains(n) then
            let new_path = path.clone()
            new_path.push(n)
            queue.push(new_path)
          end
        end
      end
    end

    out.print("Found " + all_paths.size().string() + " possible paths")
    ifdef debug then
      for cave_path in all_paths.values() do
        let str = recover String.create() end
        var first = true
        for node in cave_path.nodes() do
          if not first then
            str.push(',')
          else
            first = false
          end
          str.append(node)
        end
        Debug(consume str)
      end
    end
