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

  fun autocomple_score(): MapIs[U8, U64] val =>
    let m = recover MapIs[U8, U64].create() end
    let sc = [
      as (U8, U64):
      (')', 1)
      (']', 2)
      ('}', 3)
      ('>', 4)
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

  fun match_opener(): MapIs[U8, U8] val =>
    let m = recover MapIs[U8, U8].create() end
    let sc = [
      as (U8, U8):
      ('(', ')')
      ('[', ']')
      ('{', '}')
      ('<', '>')
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

  fun autocomplete(line: String): (String, U64) =>
    let final_array = recover Array[U8].create(line.size()) end
    let stack = Array[U8]
    for ch in line.values() do
      final_array.push(ch)
      match ch
      | let o: U8 if (o == '(') or (o == '[') or
                     (o == '{') or (o == '<')
        =>
          stack.unshift(ch)

      | let c: U8 if (c == ')') or (c == ']') or
                     (c == '}') or (c == '>')
        =>
          try stack.shift()? end
      end
    end
    var score: U64 = 0
    for remaining in stack.values() do
      try
        let m = Utils.match_opener()(remaining)?
        final_array.push(m)
        score = (score * 5) + Scores.autocomple_score()(m)?
      end
    end
    let str = String.from_array(consume final_array)
    (str, score)

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        solve(env.out, file.lines())
      end
    else
      env.err.print("Error")
    end

  fun tag solve(out: OutStream, lines: FileLines) =>
    var silver_score: U64 = 0
    var gold_scores = Array[U64].create()

    for line in lines do
      let line_val = consume val line
      let error_score = SyntaxChecker.error_score(line_val)
      silver_score = silver_score + error_score
      if error_score == 0 then
        (_, let autocomplete_score) = SyntaxChecker.autocomplete(line_val)
        if autocomplete_score != 0 then
          gold_scores.push(autocomplete_score)
        end
      end
    end

    out.print("Silver: Syntax error score: " + silver_score.string())
    gold_scores = Sort[Array[U64], U64](gold_scores)
    try
      let final_gold = gold_scores(gold_scores.size() / 2)?
      out.print("Gold: Autocomplete score: " + final_gold.string())
    end
