use "files"
use "itertools"

primitive Frequencies
  fun apply(list: Array[String] box): (U64, U64) ? =>
    var first = true
    var bit_size: USize = 0
    var frequencies = Array[U64]

    let list_size = list.size().u64()
    for line in list.values() do
      if first then
        first = false
        bit_size = line.size()
        frequencies = Array[U64].init(0, bit_size)
      end

      (let n, _) = line.read_int[U64](0 where base = 2)?
      var bit_idx: USize = 0
      while bit_idx < bit_size do
        frequencies(bit_idx)? = frequencies(bit_idx)? +
          ((n >> bit_idx.u64()) and 1)
        bit_idx = bit_idx + 1
      end
    end

    var final_number: U64 = 0
    for (idx, freq) in frequencies.pairs() do
      if freq > (list_size - freq) then
        final_number = final_number or (1 << idx.u64())
      end
    end

    (final_number, bit_size.u64())

actor Main
  var path: String = "./2021/03/input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let lines = Iter[String](file.lines()).collect(Array[String])
        silver(env, lines)?
      end
    else
      env.err.print("Error")
    end

  fun tag silver(env: Env, lines: Array[String] box) ? =>
    (let gamma, let bit_size) = Frequencies(lines)?
    let epsilon = gamma xor ((1 << bit_size) - 1)
    env.out.print((gamma * epsilon).string())
