use "files"
use "collections"

primitive Scores
  fun apply(): MapIs[U8, U64] val =>
    let m = recover MapIs[U8, U64].create() end
    let sc = [
      as (U8, U64):
      ('(', 3)
      ('[', 57)
      ('{', 1197)
      ('<', 25137)
    ]
    for (ch, score) in sc.values() do
      m.insert(ch, score)
    end
    consume val m

primitive Utils
  fun matching(): MapIs[U8, U8] val =>
    let m = recover MapIs[U8, U8].create() end
    let sc = [
      as (U8, U8):
      (')', '(')
      (']', '[')
      ('}', '{')
      ('>', '<')
    ]
    for (open, close) in sc.values() do
      m.insert(open, close)
    end
    consume val m

primitive SyntaxChecker
  fun _matching_char(ch: U8): U8 =>
    Utils.matching().get_or_else(ch, ch)

  fun _error_score(ch: U8, stack: Array[U8]): U64 =>
    try
      if stack.shift()? != ch then
        return Scores().get_or_else(ch, 0)
      end
      0
    else
      0
    end

  fun error_score(line: String): U64 =>
    let stack = Array[U8]
    for ch in line.values() do
      match ch
      | let o: U8 if (o == '(') or (o == '[') or
                     (o == '{') or (o == '<')
        =>
          stack.unshift(ch)

      | let c: U8 if (c == ')') or (c == ']') or
                     (c == '}') or (c == '>')
        =>
          let delta = _error_score(_matching_char(c), stack)
          if delta > 0 then return delta end
      end
    end
    0

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        silver(env.out, file.lines())
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, lines: FileLines) =>
    var score: U64 = 0
    for line in lines do
      score = score + SyntaxChecker.error_score(consume line)
    end
    out.print("Syntax error score: " + score.string())
