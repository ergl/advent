use "files"
use "collections"
use "itertools"

actor Solver
  let _out: OutStream
  let _crabs: Array[U64]

  new create(
    out: OutStream,
    init_crabs: Array[U64] iso)
  =>
    _out = out
    _crabs = Sort[Array[U64], U64](consume init_crabs)

  be run(fuel_cost: {(U64, I64): U64} val) =>
    var moved_to: (I64 | None) = None
    var min_fuel: U64 = U64.max_value()
    try
      let max = _crabs(_crabs.size() - 1)?
      for position in Range[I64](0, max.i64()) do
        var fuel_sum: U64 = 0
        for n in _crabs.values() do
          fuel_sum = fuel_sum + fuel_cost(n, position)
        end
        if fuel_sum < min_fuel then
          min_fuel = fuel_sum
          moved_to = position
        end
      end
    end

    match moved_to
    | None =>
      _out.print("Error simulating")
    | let pos: I64 =>
      _out.print("Done simulating. Minimum position is " +
        moved_to.string() + " for a total cost of " + min_fuel.string())
    end

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
              .map[U64]({(string)? =>
                (let days, _) = string.read_int[U64](where base = 10)?
                days
              })
              .collect(Array[U64].create(str_size))
            end

        let silver = Solver.create(env.out, recover init_state.clone() end)
        silver.run({(current, target) => (current.i64() - target).abs()})

        let gold = Solver.create(env.out, recover init_state.clone() end)
        gold.run({(current, target) =>
          let diff =  (current.i64() - target).abs()
          (diff * (diff + 1)) / 2
        })
      end
    else
      env.err.print("Error")
    end
