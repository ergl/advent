use "files"
use "collections"

primitive Utils
  fun _from_ascii(i: U8): U8? =>
    if (i < 48) or (i > 57) then
      error
    end

    i - 48

  fun process_file(env: Env, path: String, buffer: Array[U8] ref)? =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File

    for character in file.read(file.size()).values() do
      buffer.push(Utils._from_ascii(character)?)
    end

    file.dispose()

  fun pattern_index(size: USize, inner: USize, outer: USize): USize =>
    ((inner + 1) / (outer + 1)).mod(size)

  fun apply_phase(phase: U8, pattern: Array[I8] val, input: Array[U8]): Array[U8]? =>
    let buffer = Array[U8].init(0, input.size())
    let pattern_size = pattern.size()
    for i in Range.create(0, input.size()) do
      var acc: I64 = 0
      for j in Range.create(0, input.size()) do
        let element = input(j)?
        let idx = pattern_index(pattern_size, j, i)
        let mult = pattern(idx)?
        acc = acc + (element.i64() * mult.i64())
      end
      buffer(idx)? = acc.abs().mod(10).u8()
    end
    buffer

  fun do_fft(phases: U8, pattern: Array[I8] val, init_buffer: Array[U8] iso): Array[U8]? =>
    var buffer: Array[U8] ref = consume init_buffer
    var phase: U8 = 1
    while phase <= phases do
      buffer = apply_phase(phases, pattern, buffer)?
      phase = phase + 1
    end
    buffer

  fun format[A: Stringable val](buffer: Array[A], limit: USize = 0): String iso^ =>
    let str = recover String.create() end
    let limit' = if limit == 0 then buffer.size() else limit end
    try
      var idx: USize = 0
      while idx < limit do
        str.append(buffer(idx)?.string())
        idx = idx + 1
      end
    end
    consume str

actor Main
  new create(env: Env) =>
    try
      let pattern = recover val [as I8: 0; 1; 0; -1] end
      let buffer = recover
        let tmp = Array[U8].create()
        Utils.process_file(env, "./16/input.txt", tmp)?
        tmp
      end

      let result = Utils.do_fft(100, pattern, consume buffer)?
      env.out.print(Utils.format[U8](result where limit = 8))
    end
