use "files"
use "itertools"
use "buffered"

actor Main
  let _wide: U64 = 25
  let _tall: U64 = 6

  fun from_ascii(i: U8): U8? =>
    match i
    | 48 => 0
    | 49 => 1
    | 50 => 2
    else error
    end

  fun load_file(env: Env, path: String, default: Array[U8] val): Array[U8] val =>
    let r = Reader
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let str = file.read_string(file.size())
      let arr = recover Array[U8] end
      r.append(consume str)
      while true do
        try
          let v = r.u8()?
          arr.push(from_ascii(v)?)
        else
          break
        end
      end
      file.dispose()
      arr
    else
      default
    end

  fun tag acc_digits(): {((U64, U64, U64), U8): (U64, U64, U64)} =>
    object ref
      fun apply(acc: (U64, U64, U64), elt: U8): (U64, U64, U64) =>
        (let zeros, let ones, let twos) = acc
        match elt
        | 0 => (zeros + 1, ones, twos)
        | 1 => (zeros, ones + 1, twos)
        | 2 => (zeros, ones, twos + 1)
        else acc
        end
    end

  new create(env: Env) =>
    let layer_size = (_wide * _tall).usize()
    var min_zeros = U64.max_value()
    var target_ones: U64 = 0
    var target_twos: U64 = 0

    let values = Iter[U8](load_file(env, "./8/input.txt", []).values())
    while values.has_next() do
      let layer = values.take(layer_size)
      let acc = layer.fold[(U64, U64, U64)]((0, 0, 0), acc_digits())
      (let tmp_zeros, let tmp_ones, let tmp_twos) = acc
      if tmp_zeros < min_zeros then
        min_zeros = tmp_zeros
        target_ones = tmp_ones
        target_twos = tmp_twos
      end
    end

    let mult = (target_ones * target_twos)
    env.out.print("Total: ".add(mult.string()))
