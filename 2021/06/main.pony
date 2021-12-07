use "files"
use "collections"
use "itertools"

actor Nursery
  let _out: OutStream
  let _fish: Array[U64]
  var _simulation_day: U64

  new create(
    out: OutStream,
    simulation_day: U64,
    init_fish: Array[U64] iso)
  =>
    _out = out
    _fish = consume init_fish
    _simulation_day = simulation_day

  be run() =>
    try
      for i in Range[U64](0, _simulation_day) do
        let f = _fish.shift()?
        _fish.push(f)
        _fish(6)? = _fish(6)? + f
      end
    end

    let total = Iter[U64](_fish.values())
      .fold[U64](0, {(acc, elt) => acc + elt})
    _out.print("Done simulating. There are " + total.string() + " fish.")

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let str = file.read_string(file.size()).split(",")
        let str_size = str.size()
        let init_state = recover val
            Iter[String]((consume str).values())
              .map[USize]({(string)? =>
                (let days, _) = string.read_int[USize](where base = 10)?
                days
              })
              .fold_partial[Array[U64]](
                Array[U64].init(0, 9),
                {(acc, elt)? =>
                  acc(elt)? = acc(elt)? + 1
                  acc
                }
              )?
            end
        // Silver
        let silver = Nursery.create(env.out, 80, recover init_state.clone() end)
        silver.run()
        // Gold
        let gold = Nursery.create(env.out, 256, recover init_state.clone() end)
        gold.run()
      end
    else
      env.err.print("Error")
    end
