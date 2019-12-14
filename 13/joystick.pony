use "term"
use "promises"
use "package:../07"
use eleven = "package:../11"

class JoystickHandler is ReadlineNotify
  let _executor: Executor

  new create(exe: Executor) =>
    _executor = exe

  fun ref apply(line: String, prompt: Promise[String]) =>
    match line
    | "q" => prompt.reject(); return
    | "a" => _executor.input(-1); prompt("> ")
    | "d" => _executor.input(1); prompt("> ")
    | "s" => _executor.input(0); prompt("> ")
    else prompt("(try again) > ") end

  fun ref tab(line: String): Seq[String] box =>
    let r = Array[String]

    r.push("quit")
    r.push("l")
    r.push("r")
    r.push("n")

    r
