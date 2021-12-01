use "package:../07"
use eleven = "package:../11"
use thirteen = "package:../13"

actor Main
  new create(env: Env) =>
    let code = thirteen.FileUtils.load_file(env, "./15/input.txt", [])

    let executor = eleven.ProgramActor.create(consume code, DroidController.create(env.out))

    executor.turn_on()
