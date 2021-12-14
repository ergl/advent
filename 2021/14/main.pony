use "files"
use "collections"

use "debug"

type Template is Array[U8]
type Insertions is MapIs[(U8, U8), U8]

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

// primitive IterPairs
//   fun apply(a: Array[U8]): Iterator[(U8, U8)] =>
//     object
//       let _buffer: Array[U8] = a
//       let _buffer_size: USize = a.size()
//       var _index: USize = 0

//       fun ref has_next(): Bool =>
//         _index <= (_buffer_size - 2)

//       fun ref next(): (U8, U8) ? =>
//         let pair = (
//           _buffer(_index)?,
//           _buffer(_index + 1)?
//         )
//         _index = _index + 1
//         pair
//     end

// primitive IterPairsReverse
//   fun apply(a: Array[U8]): Iterator[(U8, U8)] =>
//     object
//       let _buffer: Array[U8] = a
//       var _index: USize = (a.size() - 1)

//       fun ref has_next(): Bool =>
//         _index > 0

//       fun ref next(): (U8, U8) ? =>
//         let pair = (
//           _buffer(_index - 1)?,
//           _buffer(_index)?
//         )
//         _index = _index - 1
//         pair
//     end

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
  let path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        (let template, let insertions) = ParseInput(file.lines())?
        silver(env.out, template, insertions, 10)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(
    out: OutStream,
    template: Template val,
    changes_table: Insertions val,
    steps: U8)
  =>
    let polymer = template.clone()
    var step: U8 = 0

    Debug("Template: " + ArrayToString(polymer))
    try
      while step < steps do
        var index: USize = 1
        while index < polymer.size() do
          let pair = (polymer(index - 1)?, polymer(index)?)
          polymer.insert(index, changes_table(pair)?)?
          index = index + 2
        end
        ifdef debug then
          Debug(
            "After step " + (step+1).string() + ": " +
            ArrayToString(polymer)
          )
        end
        step = step + 1
      end
    end

    let frequencies = MapIs[U8, U64].create()
    for elt in polymer.values() do
      frequencies.upsert(elt, 1, {(c,p) => c + p})
    end

    (var max_freq: U64, var max_value: U8) = (0, 0)
    (var min_freq: U64, var min_value: U8) = (U64.max_value(), 0)

    for (c, freq) in frequencies.pairs() do
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
    out.print("Silver. Solution: " + (max_freq - min_freq).string())

