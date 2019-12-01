use "files"
use "collections"
use "itertools"

actor Main
  var path: String = "./1/input.txt"

  fun _get_fuel(number: U64): U64 =>
    let partial = number.f64().div(3.0).floor().u64()
    if partial < 2 then
      0
    else
      partial - 2
    end

  fun _fuel_for_fuel(remainder: U64, total: U64): U64 =>
    if remainder == 0 then
      total
    else
      let extra_fuel = _get_fuel(remainder)
      _fuel_for_fuel(extra_fuel, total + extra_fuel)
    end

  fun _total_fuel(number: U64): U64 =>
    let fuel = _get_fuel(number)
    _fuel_for_fuel(fuel, fuel)

  fun _parse_input(input: String val): U64 =>
    try
      input.u64()?
    else
      0
    end

  new create(env: Env) =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end

    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      do
        let answer = Iter[String](file.lines())
                      .fold[U64](0, {(acc, elt)(that=this) =>
                          acc + that._total_fuel(that._parse_input(elt))})

        env.out.print(answer.string())
      end
    else
      env.out.print("Couldn't open ".add(path))
    end
