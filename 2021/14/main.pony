use "files"
use "collections"

use "debug"

type Template is Array[U8]
type Insertions is MapIs[(U8, U8), U8]

primitive IterPairs
  fun apply(a: Array[U8] box): Iterator[(U8, U8)] =>
    object
      let _buffer: Array[U8] box = a
      let _buffer_size: USize = a.size()
      var _index: USize = 0

      fun ref has_next(): Bool =>
        _index <= (_buffer_size - 2)

      fun ref next(): (U8, U8) ? =>
        let pair = (
          _buffer(_index)?,
          _buffer(_index + 1)?
        )
        _index = _index + 1
        pair
    end


primitive ASCII
  fun apply(ch: U8): String =>
    recover String.from_utf32(ch.u32()) end

primitive ArrayToString
  fun apply(a: Array[U8] box): String =>
    let str = recover String.create(a.size()) end
    for v in a.values() do
      str.push(v)
    end
    consume str

primitive ParseInput
  fun apply(lines: FileLines): (Template val, Insertions val) ? =>
    let template = recover Template.create() end
    let insertions = recover Insertions.create() end

    var first = true
    for line in lines do
      if first then
        let l = consume val line
        for byte in l.values() do
          template.push(byte)
        end
        first = false
        continue
      end

      if line.size() == 0 then
        continue
      end

      let parts = (consume line).split(" ", 3)

      // Origin is always two bytes
      // Destination is always a single byte
      let origin = parts(0)?
      let dest = parts(2)?(0)?
      (let origin_1, let origin_2) = (origin(0)?, origin(1)?)
      insertions.insert((origin_1, origin_2), dest)
    end

    (consume val template, consume val insertions)

actor Main
  let path: String = "./input_sample.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        (let template, let insertions) = ParseInput(file.lines())?
        solve(env.out, template, insertions, 10)
      end
    else
      env.err.print("Error")
    end

  fun tag solve(
    out: OutStream,
    template: Template val,
    changes_table: Insertions val,
    steps: U8)
  =>

    let freqs = MapIs[U8, I64].create()
    let pair_frequencies = MapIs[(U8, U8), I64].create()

    for (left, right) in IterPairs(template) do
      freqs.insert(left, 1 + freqs.get_or_else(left, 0))
      freqs.insert(right, 1 + freqs.get_or_else(right, 0))
      let pair = (left, right)
      pair_frequencies.insert(
        pair,
        1 + pair_frequencies.get_or_else(pair, 0)
      )
    end

    var step: U8 = 0
    while step < steps do
      let step_generations = MapIs[(U8, U8), I64].create()
      for (pair, change) in changes_table.pairs() do

        (let left, let right) = pair
        let freq = pair_frequencies.get_or_else(pair, 0)
        freqs.insert(change, freq + freqs.get_or_else(change, 0))

        ifdef debug then
          Debug(
            "Step " + step.string() + " found " + freq.string() + " pairs of " +
            ASCII(left) + "," + ASCII(right)
            + ". Generates " + freq.string() + " pairs of " +
            ASCII(left) + "," + ASCII(change) + " and " + 
            ASCII(change) + "," + ASCII(right)
          )
        end

        step_generations.insert(
          pair,
          step_generations.get_or_else(pair, 0) - freq
        )

        step_generations.insert(
          (left, change),
          freq + step_generations.get_or_else((left, change), 0)
        )

        step_generations.insert(
          (change, right),
          freq + step_generations.get_or_else((change, right), 0)
        )
      end
      for (pair, f) in step_generations.pairs() do
        pair_frequencies.insert(
          pair,
          pair_frequencies.get_or_else(pair, 0) + f
        )
      end
      step = step + 1
    end

    (var max_freq: I64, var max_value: U8) = (0, 0)
    (var min_freq: I64, var min_value: U8) = (I64.max_value(), 0)

    for (c, freq) in freqs.pairs() do
      if freq > max_freq then
        max_freq = freq
        max_value = c
      elseif freq < min_freq then
        min_freq = freq
        min_value = c
      end
    end

    out.print(
      "Most common: " + ASCII(max_value) +
      " appears " + max_freq.string() + " times."
    )
    out.print(
      "Least common: " + ASCII(min_value) +
      " appears " + min_freq.string() + " times."
    )
    out.print("Solution: " + (max_freq - min_freq).string())

  // fun tag expand_pair(
  //   a: U8,
  //   b: U8,
  //   steps: U8,
  //   changes: Insertions val,
  //   freqs: MapIs[U8, U64],
  //   stack: Array[(U8, U8, U8)])
  // =>
  //   stack.unshift((a, b, 0))
  //   try
  //     while true do
  //       (let left, let right, let step) = stack.shift()?
  //       if step < steps then
  //         let c = changes((left, right))?
  //         freqs.insert(c, 1 + freqs.get_or_else(c, 0))
  //         ifdef debug then
  //           Debug(
  //             ASCII(left) + " plus " + ASCII(right) + " generates " + ASCII(c)
  //           )
  //         end
  //         stack.unshift((c, right, step + 1))
  //         stack.unshift((left, c, step + 1))
  //       end
  //     end
  //   end
