use "itertools"

class ref IOQueue
  let _buffer: Array[I64]

  new create() =>
    _buffer = Array[I64].create()

  fun ref get(): (I64 | None) =>
    try _buffer.pop()? else None end

  fun ref put(x: I64) =>
    _buffer.unshift(x)

primitive Utils
  fun parse_input(input: String): I64 =>
    try input.i64()? else 0 end

  fun to_string(arr: Phase): String =>
    Iter[I64](arr.values())
      .fold[String]("[", {(acc, elt) => acc.add(elt.string().add(";"))}).add("]")

  fun permute(phase: Phase): Iter[Phase] =>
    let target = try
      permutations(phase)?.values()
    else
      [phase].values()
    end
    Iter[Phase](target)

  fun permutations(input: Phase): Array[Phase]? =>
    let acc = Array[Phase].create()
    _permute(input.clone(), 0, acc)?
    acc

  fun _permute(input: Array[I64], k: USize, acc: Array[Phase])? =>
    let size = input.size()
    var idx = k
    while idx < size do
      input.swap_elements(idx, k)?
      _permute(input, k + 1, acc)?
      input.swap_elements(k, idx)?
      idx = idx + 1
    end

    if k == (size - 1) then
      let input_clone = recover Array[I64].create() end
      for elt in input.values() do
        input_clone.push(elt)
      end
      acc.push(consume input_clone)
    end
