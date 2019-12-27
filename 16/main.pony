use "files"
use "collections"

primitive Utils
  fun _from_ascii(i: U8): U8? =>
    if (i < 48) or (i > 57) then
      error
    end

    i - 48

  fun to_usize(arr: Array[U8]): USize =>
    var idx: USize = arr.size() - 1
    var acc: USize = 0
    var mult: USize = 1
    try
      while idx >= 0 do
        acc = acc + (arr(idx)?.usize() * mult)
        mult = mult * 10
        idx = try idx -? 1 else break end
      end
    end
    acc

  fun process_file(env: Env, path: String, buffer: Array[U8] ref, digits: USize): USize =>
    let offset_arr = Array[U8].create(digits)
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      var offset: USize = 0
      for character in file.read(file.size()).values() do
        let char = Utils._from_ascii(character)?
        if offset < digits then
          offset_arr.push(char)
        end

        buffer.push(char)
        offset = offset + 1
      end

      file.dispose()
    end
    to_usize(offset_arr)

  fun sum_rest(in_buffer: Array[U8], out_buffer: Array[U8])? =>
    let size = in_buffer.size()
    var i = size - 1
    var acc: USize = 0
    while i >= 0 do
      acc = acc + in_buffer(i)?.usize()
      out_buffer(i)? = acc.mod(10).u8()
      i = i -? 1
    end

  fun extract_msg(phases: U8, msg_size: USize, init_buffer: Array[U8] iso): USize =>
    let buffer_size = init_buffer.size()
    let buffer: Array[U8] ref = consume init_buffer
    let tmp_buffer = Array[U8].init(0, buffer.size()) // Extra buffer we don't allocate on sum_rest
    for p in Range[U8](0, phases) do
      try sum_rest(buffer, tmp_buffer)? end
      tmp_buffer.copy_to(buffer where src_idx = 0, dst_idx = 0, len = buffer_size)
    end
    to_usize(buffer.slice(where to = msg_size))

  fun extend_slice(buffer: Array[U8] iso, from: USize, to: USize): Array[U8] iso^ =>
    let buf_size = buffer.size()
    let slice_size = to - from
    let slice = recover Array[U8].init(0, slice_size) end
    try
      for i in Range(0, slice_size) do
        slice(i)? = buffer((from + i).mod(buf_size))?
      end
    end
    consume slice

actor Main
  new create(env: Env) =>
    let msg_size: USize = 8
    let times: USize = 10_000
    let offset_digits: USize = 7

    (let buffer, let offset) = recover
      let tmp = Array[U8].create()
      let offset = Utils.process_file(env, "./16/input.txt", tmp, offset_digits)
      (tmp, offset)
    end

    let new_size = buffer.size() * times
    if offset > (new_size + msg_size) then
      env.err.print("Offset is too long! (" + offset.string() + " > " + new_size.string() + ")")
      return
    end

    let extended_buffer = Utils.extend_slice(consume buffer, offset, new_size)
    let msg = Utils.extract_msg(100, msg_size, consume extended_buffer)
    env.out.print("Msg is " + msg.string())
