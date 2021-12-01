use "files"
use "itertools"

actor Main
  var path: String = "./2021/01/input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let lines =
          Iter[String](file.lines())
            .map[U64]({(elt)? => elt.u64()?})
            .collect(Array[U64].create())

        var increase = U64(0)
        var prev: (U64 | None) = None
        for elt in lines.values() do
          match prev
          | None => prev = elt
          | let previous: U64 =>
            if previous < elt then
              increase = increase + 1
            end
            prev = elt
          end
        end
        env.out.print(increase.string())
      end
    else
      env.err.print("Couldn't open " + path)
    end
