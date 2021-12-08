use "files"
use "collections"
use "itertools"
use "debug"

class val StringHash is HashFunction[String]
  new val create() => None
  fun hash(s: String): USize => s.hash()
  fun eq(left: String, right: String): Bool => left == right

type SignalDictionary is HashMap[String, U8, StringHash]

primitive ArrayUtils
  fun to_num(arr: Array[U8] box): U64 =>
    var mult: U64 = 1
    var total: U64 = 0
    for v in arr.reverse().values() do
      total = total + (v.u64() * mult)
      mult = mult * 10
    end
    total

primitive StringUtils
  fun different_bytes(a: String, b: String): Array[U8] iso^ =>
    (let to_iterate, let other) =
      if a.size() > b.size() then
        (a.array(), b.array())
      else
        (b.array(), a.array())
      end

      let iterate_size = to_iterate.size()
      let different = recover Array[U8].create(iterate_size) end
      for byte in to_iterate.values() do
        try
          other.find(byte)?
        else
          different.push(byte)
        end
      end
      consume different

  fun without_byte(str: String, b: U8): String =>
    let res = recover String end
    for byte in str.values() do
      if byte != b then
        res.push(byte)
      end
    end
    consume res

  fun hamming(a: String box, b: String box): USize ? =>
    if a.size() != b.size() then
      error
    end

    var distance: USize = 0
    var idx: USize = 0
    for byte in a.values() do
      if byte != b(idx)? then
        distance = distance + 1
      end
      idx = idx + 1
    end
    distance

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

  fun decode_output_signals(): U64 ? =>
    let dictionary = _build_dictionary()?
    let output = Array[U8].create(_output_signals.size())
    for s in _output_signals.values() do
      output.push(dictionary(s)?)
    end
    ArrayUtils.to_num(output)

  fun _build_dictionary(): SignalDictionary iso^ ? =>
    let dictionary = recover SignalDictionary end

    let one = _get_with_size(_input_signals, 2)(0)?
    let seven = _get_with_size(_input_signals, 3)(0)?
    let three = _get_three()?
    let four = _get_with_size(_input_signals, 4)(0)?
    let eight = _get_with_size(_input_signals, 7)(0)?

    // Only one difference
    let upper_segment = StringUtils.different_bytes(one, seven)(0)?
    (let nine, let lower_segment) = _get_nine(four, upper_segment)?
    (
      let zero, let middle_segment,
      let six, let upper_right_segment
    ) = _get_zero_and_six(one, eight, nine, upper_segment, lower_segment)?
    (let two, let five) = _get_two_and_five(three, upper_right_segment)?

    dictionary(zero) = 0
    dictionary(one) = 1
    dictionary(two) = 2
    dictionary(three) = 3
    dictionary(four) = 4
    dictionary(five) = 5
    dictionary(six) = 6
    dictionary(seven) = 7
    dictionary(eight) = 8
    dictionary(nine) = 9

    Debug("Zero is " + zero)
    Debug("One is " + one)
    Debug("Two is " + two)
    Debug("Three is " + three)
    Debug("Four is " + four)
    Debug("Five is " + five)
    Debug("Six is " + six)
    Debug("Seven is " + seven)
    Debug("Eight is " + eight)
    Debug("Nine is " + nine)
    Debug(
      "Upper segment is " +
      recover val String.from_utf32(upper_segment.u32()) end
    )
    Debug(
      "Upper right segment is " +
      recover val String.from_utf32(upper_right_segment.u32()) end
    )
    Debug(
      "Middle segment is " +
      recover val String.from_utf32(middle_segment.u32()) end
    )
    Debug(
      "Lower segment is " +
      recover val String.from_utf32(lower_segment.u32()) end
    )

    consume dictionary

  fun box _get_three(): String ? =>
    let candidates = _get_with_size(_input_signals, 5)
    // Only three numbers: 2, 3 and 5
    let c1 = candidates(0)?
    let c2 = candidates(1)?
    let c3 = candidates(2)?

    if
      (StringUtils.hamming(c1, c2)? == 1) and
      (StringUtils.hamming(c1, c3)? == 1)
    then
      return c1
    elseif
      (StringUtils.hamming(c2, c1)? == 1) and
      (StringUtils.hamming(c2, c3)? == 1)
    then
      return c2
    else
      return c3
    end

  fun box _get_nine(four: String, upper_segment_byte: U8): (String, U8) ? =>
    let candidates = _get_with_size(_input_signals, 6)
    let c1 = candidates(0)?
    let c1_cut = StringUtils.without_byte(c1, upper_segment_byte)
    let c2 = candidates(1)?
    let c2_cut = StringUtils.without_byte(c2, upper_segment_byte)
    let c3 = candidates(2)?
    let c3_cut = StringUtils.without_byte(c3, upper_segment_byte)

    let c1_diff = StringUtils.different_bytes(c1_cut, four)
    let c2_diff = StringUtils.different_bytes(c2_cut, four)
    let c3_diff = StringUtils.different_bytes(c3_cut, four)
    if c1_diff.size() == 1 then
      return (c1, c1_diff(0)?)
    elseif c2_diff.size() == 1 then
      return (c2, c2_diff(0)?)
    else
      return (c3, c3_diff(0)?)
    end

  fun box _get_zero_and_six(
    one: String,
    eight: String,
    nine: String,
    upper_segment_byte: U8,
    lower_segment_byte: U8)
    : (String, U8, String, U8)
    ?
  =>
    let one_array = one.array()

    // Zero or Six
    let candidates =
      Iter[String](_get_with_size(_input_signals, 6).values())
        .filter({(elt) => elt != nine})
        .collect(Array[String])

    let eight_cut =
      StringUtils.without_byte(
        StringUtils.without_byte(eight, upper_segment_byte),
        lower_segment_byte
      )

    let c1 = candidates(0)?
    let c1_cut =
      StringUtils.without_byte(
        StringUtils.without_byte(c1, upper_segment_byte),
        lower_segment_byte
      )

    let c2 = candidates(1)?
    let c2_cut =
      StringUtils.without_byte(
          StringUtils.without_byte(c2, upper_segment_byte),
          lower_segment_byte
        )

    // We know there's only one in difference
    let c1_diff = StringUtils.different_bytes(c1_cut, eight_cut)(0)?
    let c2_diff = StringUtils.different_bytes(c2_cut, eight_cut)(0)?

    if not one_array.contains(c1_diff, {(l, r) => l == r}) then
      // c1 is zero, c2 is six
      return (c1, c1_diff, c2, c2_diff)
    else
      return (c2, c2_diff, c1, c1_diff)
    end

  fun box _get_two_and_five(
    three: String,
    upper_right_segment_byte: U8)
    : (String, String)
    ?
  =>
    // Two or Five
    let candidates =
      Iter[String](_get_with_size(_input_signals, 5).values())
        .filter({(elt) => elt != three})
        .collect(Array[String])

    let c1 = candidates(0)?
    let c2 = candidates(1)?

    if c1.array().contains(upper_right_segment_byte, {(l, r) => l == r}) then
      return (c1, c2)
    else
      return (c2, c1)
    end

  fun tag _get_with_size(
    arr: Array[String] box,
    size: USize)
    : Array[String] box
  =>
    Iter[String](arr.values())
      .filter({(signal) => signal.size() == size})
      .collect(Array[String])

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
  var path: String = "./input_sample.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let entries = Array[Entry].create()
        for line in file.lines() do
          entries.push(ParseLine(consume line)?)
        end
        // silver(env.out, entries)
        gold(env.out, entries)
      end
    else
      env.err.print("Error")
    end

  fun tag silver(out: OutStream, entries: Array[Entry] box) =>
    var count: USize = 0
    for entry in entries.values() do
      out.print(entry.string())
      // try entry.dictionary(out)? end
      count = count + entry.unique_output_signals()
    end
    out.print("Unique signals in output: " + count.string())

  fun tag gold(out: OutStream, entries: Array[Entry] box) =>
    var count: U64 = 0
    for entry in entries.values() do
      try
        let c = entry.decode_output_signals()?
        out.print(entry.string() + ": " + c.string())
        count = count + c
      end
    end
    out.print("Sum of output signals: " + count.string())
