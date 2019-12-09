use "package:../7"
use "files"
use "itertools"

primitive FileUtils
  fun load_file(env: Env, path: String, default: Array[I64] val): Array[I64] val =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let arr: Array[I64] val = recover val
        Iter[String](file.read_string(file.size()).split_by(",").values())
          .map[I64]({(elt) => try elt.i64()? else 0 end})
          .collect(Array[I64])
      end
      file.dispose()
      arr
    else
      default
    end

actor Main
  new create(env: Env) =>
    let code = FileUtils.load_file(env, "./9/input.txt", [])

    let queue_1 = IOQueue.>put(1)
    let out_fn_1 = {(elt: I64)(env) => env.out.print("Part 1: ".add(elt.string()))}
    let program_1 = Program.create(queue_1, out_fn_1, code)
    while not program_1.finished do
      program_1.step()
    end

    let queue_2 = IOQueue.>put(2)
    let out_fn_2 = {(elt: I64)(env) => env.out.print("Part 2: ".add(elt.string()))}
    let program_2 = Program.create(queue_2, out_fn_2, code)
    while not program_2.finished do
      program_2.step()
    end
