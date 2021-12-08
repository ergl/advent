use "files"
use "collections"

primitive ParseLine
  fun apply(line: String iso): Entry iso^ ? =>
    let offset = line.rfind("|")?
    (var input, var output) = (consume line).chop(offset.usize())
    // Remove leading and trailing whitespace
    input.rstrip()
    output.cut_in_place(0, 2)

    let input_signals = recover Array[String] end
    for signal in (consume input).split(" ").values() do
      input_signals.push(sort_signal(signal))
    end

    let output_signals = recover Array[String] end
    for signal in (consume output).split(" ").values() do
      output_signals.push(sort_signal(signal))
    end

    recover
      Entry.create(consume input_signals, consume output_signals)
    end

  fun sort_signal(signal: String): String =>
    let arr =
      recover
        let tmp = Array[U8].create(signal.size())
        for byte in signal.values() do
          tmp.push(byte)
        end
        Sort[Array[U8], U8](tmp)
      end
    String.from_iso_array(consume arr)

class Entry
  let _input_signals: Array[String]
  let _output_signals: Array[String]

  new create(input: Array[String] iso, output: Array[String] iso) =>
    _input_signals = consume input
    _output_signals = consume output

  fun unique_output_signals(): USize =>
    var count: USize = 0
    for signal in _output_signals.values() do
      match signal.size()
      | let s: USize if (s == 2) or (s == 3) or (s == 4) or (s == 7) =>
        count = count + 1
      end
    end
    count

  fun string(): String iso^ =>
    let init_size = _input_signals.size() + _output_signals.size() + 1
    let str = recover
      String.create(init_size)
    end
    for s in _input_signals.values() do
      str.>append(s).push(' ')
    end
    str.append("| ")
    for s in _output_signals.values() do
      str.>append(s).push(' ')
    end
    str.rstrip()
    consume str

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let entries = Array[Entry].create()
        for line in file.lines() do
          entries.push(ParseLine(consume line)?)
        end
        silver(env.out, entries)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, entries: Array[Entry] box) =>
    var count: USize = 0
    for entry in entries.values() do
      count = count + entry.unique_output_signals()
    end
    out.print("Unique signals in output: " + count.string())
