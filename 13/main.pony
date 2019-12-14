use "term"
use "files"
use "itertools"
use "package:../07"
use eleven = "package:../11"

primitive FileUtils
  fun load_file(env: Env, path: String, default: Array[I64] iso): Array[I64] iso^ =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let arr = recover
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
    let code = FileUtils.load_file(env, "./13/input.txt", [])
    try code(0)? = 2 end

    let arcade = Arcade.create(env.out)
    let executor = eleven.ProgramActor.create(consume code, arcade)
    let term = ANSITerm(
      Readline(recover JoystickHandler.create(executor) end, env.out),
      env.input
    )

    let notify = object iso
      let term : ANSITerm = term
      fun ref apply(data: Array[U8] iso) => term(consume data)
      fun ref dispose() => term.dispose()
    end

    executor.turn_on()
    term.prompt("> ")
    env.input(consume notify)
