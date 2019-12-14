use "files"
use "itertools"
use "package:../07"

interface tag FSM
  be state_msg(i: I64)
  be subscribe(exe: Executor)
  be unsubscribe()

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
    let code = FileUtils.load_file(env, "./11/input.txt", [])

    let robot = Robot.create(env.out)
    let executor = ProgramActor.create(code, robot)

    executor.turn_on()
