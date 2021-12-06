use "files"
use "collections"
use "itertools"

actor Collector
  let _out: OutStream
  let _fish: SetIs[Lantern] = _fish.create()
  var _created: U64 = 0

  new create(out: OutStream) =>
    _out = out

  be spawned(fish: Lantern) =>
    _created = _created + 1
    _fish.set(fish)

  be done(fish: Lantern) =>
    _fish.unset(fish)
    if _fish.size() == 0 then
      _out.print("Done simulating. There are " + _created.string() + " fish.")
    end

actor Lantern
  var _simulation_step: U64
  var _day: U64
  let _collector: Collector

  new create(
    simulation_days: U64,
    fish_day: U64,
    collector: Collector)
  =>
    _simulation_step = simulation_days
    _day = fish_day
    _collector = collector
    _notify_collector()

  be _notify_collector() =>
    let self: Lantern tag = this
    _collector.spawned(self)
    step()

  be step() =>
    if _simulation_step == 0 then
      _collector.done(this)
      return
    end

    _simulation_step = _simulation_step - 1
    if _day == 0 then
      _day = 6
      // New lanternfish are created with 8 days
      Lantern.create(_simulation_step, 8, _collector)
    else
      _day = _day - 1
    end

    step()

actor Main
  var path: String = "./input.txt"

  new create(env: Env) =>
    try
      with file = OpenFile(FilePath(env.root as AmbientAuth, path)) as File
      do
        let str: Array[String] = file.read_string(file.size()).split(",")
        let init_state =
          Iter[String](str.values())
            .map[U64]({(str)? => str.read_int[U64](where base = 10)?._1})
            .collect(Array[U64].create(str.size()))
        let c = Collector.create(env.out)
        for l in init_state.values() do
          Lantern.create(80, l, c)
        end
      end
    else
      env.err.print("Error")
    end
