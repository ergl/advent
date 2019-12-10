actor Main
  fun valid(arr: Array[U8]): Bool =>
    try
      let repeats = Array[U8].init(0, 10)
      var prev = arr(0)?
      var idx = USize(1)
      var n = U8(0)
      while idx < 6 do
        n = arr(idx)?
        if n < prev then
          return false
        elseif n == prev then
          let prev_c = repeats(n.usize())?
          let incr = if prev_c == 0 then 2 else 1 end
          repeats.update(n.usize(), prev_c + incr)?
        end
        prev = n
        idx = idx + 1
      end
      repeats.contains(2)
    else
      false
    end

  fun incr(arr: Array[U8]) =>
    try
      var idx: USize = 5
      var n = U8(0)
      var prev= U8(0)
      while idx >= 0 do
        prev=arr(idx)?
        n = (prev + 1).mod(10)
        arr.update(idx, n)?
        if prev < n then
          break
        end
        idx = idx - 1
      end
    else
      None
    end

  fun lt(left: Array[U8], right: Array[U8]): Bool =>
    try
      var idx = USize(0)
      var left_v = U8(0)
      var right_v = U8(0)
      while idx < 6 do
        left_v = left(idx)?
        right_v = right(idx)?
        if left_v > right_v then
          return false
        elseif left_v < right_v then
          return true
        end
        idx = idx + 1
      end
      true
    else
      false
    end

  new create(env: Env) =>
    let min: Array[U8] = [3;7;2;3;0;4]
    let max: Array[U8] = [8;4;7;0;6;0]
    var count = U64(0)
    while lt(min, max) do
      if valid(min) then
        count = count + 1
      end
      incr(min)
    end
    env.out.print(count.string())
