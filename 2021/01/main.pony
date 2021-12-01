use "files"
use "collections/persistent"
use "itertools"

actor Main
  var path: String = "./2021/01/input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let lines: List[U64] =
          Iter[String](file.lines())
            .map[U64]({(elt)? => elt.u64()?})
            .fold[List[U64]](Nil[U64], {(acc, elt) => Cons[U64].create(elt, acc)})
        let windows = split_windows(lines)?
        let total = add_differences(windows)?
        env.out.print(total.string())
      end
    else
      env.err.print("Error")
    end

  fun tag split_windows(lines: List[U64]): List[U64]? =>
    let list = lines as Cons[U64]
    let first: U64 = list.head()
    var tail = list.tail()
    let second: U64 = tail.head()?
    tail = tail.tail()?
    split_windows_2(tail, first + second, second, Nil[U64])

  fun tag split_windows_2(list: List[U64], first: U64, second: U64, acc: List[U64]): List[U64] =>
    match list
    | Nil[U64] => acc
    | let c: Cons[U64] =>
      let head = c.head()
      split_windows_2(c.tail(), head + second, head, Cons[U64](head + first, acc))
    end

  fun tag add_differences(list: List[U64]): U64 ? =>
    let hd = list.head()?
    let tl = list.tail()?
    let res = tl.fold[(U64, U64)](
      {(acc, elt) =>
        (let prev, let n) = acc
        if elt > prev then
          (elt, n + 1)
        else
          (elt, n)
        end
      }, (hd, 0))
    res._2
