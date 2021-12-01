use "time"

interface tag Amplifier
  be receive(i: I64)
  be receive_sink(i: I64)
  be add_next(amp: Amplifier)
  be add_sink(amp: Amplifier)

interface tag Executor
  be turn_on()
  be turn_off()
  be step()
  be input(i: I64)

class StepTimer is TimerNotify
  let _exec: Executor

  new create(exec: Executor) =>
    _exec = exec

  fun ref apply(timer: Timer, count: U64): Bool =>
    _exec.step()
    true

  fun ref cancel(timer: Timer) =>
    None

actor ProgramExecutor is (Amplifier & Executor)
  var _next: (Amplifier | None) = None
  var _sink: (Amplifier | None) = None

  let _inbox: IOQueue
  let _program: Program
  let _timer_wheel: Timers
  var _timer_handle: (Timer tag | None) = None

  new create(wheel: Timers, memory: Array[I64] val) =>
    _inbox = IOQueue.create()
    let send_fn = {(elt: I64)(that=this) => that.send_output(elt)}
    _program = Program.create(_inbox, send_fn, memory)
    _timer_wheel = wheel

  be add_next(amp: Amplifier) => _next = amp
  be add_sink(amp: Amplifier) => _sink = amp

  be receive(i: I64) => _inbox.put(i)
  be receive_sink(i: I64) => None

  be input(i: I64) => None

  be send_output(elt: I64) =>
    match _next
    | let amp: Amplifier => amp.receive(elt)
    end

    match _sink
    | let amp: Amplifier => amp.receive_sink(elt)
    end

  be turn_on() =>
    let step_timer = recover StepTimer(this) end
    let timer_handle = Timer(consume step_timer, 5_000_000, 2_000_000)
    // Keep the tag around to cancel it in the future
    _timer_handle = recover tag timer_handle end
    _timer_wheel(consume timer_handle)

  be step() =>
    _program.step()
    if _program.finished then
      match _timer_handle
      | let t: Timer tag => _timer_wheel.cancel(t)
      end
    end

  be turn_off() =>
    try _timer_wheel.cancel(_timer_handle as Timer tag) end
