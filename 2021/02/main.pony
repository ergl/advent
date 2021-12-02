use "files"
use "itertools"

primitive Forward
primitive Up
primitive Down
type Direction is (Forward | Up | Down)

type Command is (Direction, U64)

primitive Parse
  fun line(str: String box): Command ? =>
    let parts = str.split(" ", 2)
    let command: String = parts(0)?.lower()
    let units = parts(1)?.u64()?
    match command
    | "forward" => (Forward, units)
    | "down" => (Down, units)
    | "up" => (Up, units)
    else
      error
    end

actor Main
  var path: String = "./2021/02/input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let commands = Iter[String](file.lines()).map[Command]({(elt)? => Parse.line(elt)?}).collect(Array[Command])
        solve_part_1(env.out, commands)
        solve_part_2(env.out, commands)
      end
    else
      env.err.print("Error")
    end

  fun tag solve_part_1(out: OutStream, cmds: Array[Command]) =>
    var x: I64 = 0
    var y: I64 = 0
    for cmd in cmds.values() do
      match cmd
      | (Forward, let u: U64) => x = x + u.i64()
      | (Up, let u: U64) => y = y - u.i64()
      | (Down, let u: U64) => y = y + u.i64()
      end
    end
    out.print(
      "Part 1. Final position: " +
      x.string() + ", " + y.string() +
      ". Total: " + (x*y).string()
    )

  fun tag solve_part_2(out: OutStream, cmds: Array[Command]) =>
    var x: I64 = 0
    var y: I64 = 0
    var aim: I64 = 0
    for cmd in cmds.values() do
      match cmd
      | (Forward, let u: U64) =>
        x = x + u.i64()
        y = y + (aim * u.i64())
      | (Up, let u: U64) => aim = aim - u.i64()
      | (Down, let u: U64) => aim = aim + u.i64()
      end
    end
    out.print(
      "Part 2. Final position: " +
      x.string() + ", " + y.string() +
      ". Total: " + (x*y).string()
    )
