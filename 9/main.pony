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
    let out_fn = {(elt: I64)(env) => env.out.print(elt.string())}

    let queue = IOQueue.>put(1)
    let code = FileUtils.load_file(env, "./9/input.txt", [])
    let program = Program.create(queue, out_fn, code)
    while not program.finished do
      program.step()
    end
