// use "term"
// use "promises"
// use "package:../07"
// use eleven = "package:../11"

// class JoystickHandler is ReadlineNotify
//   let _arc: Arcade

//   new create(arcade: Arcade) =>
//     _arc = arcade

//   fun ref apply(line: String, prompt: Promise[String]) =>
//     match line
//     | "q" => prompt.reject(); return
//     | "s" => _arc.move_paddle();  prompt("> ")
//     else prompt("(try again) > ") end

//   fun ref tab(line: String): Seq[String] box =>
//     let r = Array[String]

//     r.push("quit")
//     r.push("l")
//     r.push("r")
//     r.push("n")

//     r
