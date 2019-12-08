use "files"
use "itertools"
use "time"

type Phase is Array[I64] val

actor Main is Amplifier
  let _timer_wheel: Timers

  let _out: OutStream
  var _max_so_far: I64 = 0
  var _current_phase: (Phase | None) = None
  var _phase_iter: Iter[Phase]

  var _program: Array[I64] val

  be add_next(amp: Amplifier) => None
  be add_sink(amp: Amplifier) => None

  be receive(i: I64) => None
  be receive_sink(i: I64) =>
    match _current_phase
    | let p: Phase =>
      _max_so_far = _max_so_far.max(i)
      _out.print("Max so far: ".add(_max_so_far.string()))
    end

    solve_permutations()

  fun ref _run_for_combination(phase: Phase)? =>
    let program_a = ProgramExecutor.create(_timer_wheel, _program)
    let program_b = ProgramExecutor.create(_timer_wheel, _program)
    let program_c = ProgramExecutor.create(_timer_wheel, _program)
    let program_d = ProgramExecutor.create(_timer_wheel, _program)
    let program_e = ProgramExecutor.create(_timer_wheel, _program)

    program_a.receive(phase(0)?)
    program_a.receive(0)
    program_b.receive(phase(1)?)
    program_c.receive(phase(2)?)
    program_d.receive(phase(3)?)
    program_e.receive(phase(4)?)

    program_a.add_next(program_b)
    program_b.add_next(program_c)
    program_c.add_next(program_d)
    program_d.add_next(program_e)
    program_e.add_next(program_a)
    program_e.add_sink(this)

    program_a.turn_on()
    program_b.turn_on()
    program_c.turn_on()
    program_d.turn_on()
    program_e.turn_on()

  fun tag load_file(env: Env, path: String): Array[I64] val =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let program_arr: Array[I64] val = try
      let file = OpenFile(FilePath(env.root as AmbientAuth, path, caps)?) as File
      let arr: Array[I64] val = recover val
        Iter[String](file.read_string(file.size()).split_by(",").values())
          .map[I64]({(elt) => Utils.parse_input(elt)})
          .collect(Array[I64](10))
      end
      file.dispose()
      arr
    else
      env.out.print("Couldn't open ".add(path).add(", returning default program"))
      [as I64: 3;15;3;16;1002;16;10;16;1;16;15;15;4;15;99;0;0]
    end

    program_arr

  be solve_permutations() =>
    try
      if _phase_iter.has_next() then
        match _phase_iter.next()?
        | let p: Phase =>
          _current_phase = p
          _run_for_combination(p)?
        end
      end
    end

  new create(env: Env) =>
    _out = env.out
    _timer_wheel = Timers
    _program = load_file(env, "./7/input.txt")
    _phase_iter = Utils.permute([as I64: 5; 6; 7; 8; 9])
    solve_permutations()
