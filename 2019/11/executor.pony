use "package:../07"
use "time"

actor ProgramActor is Executor
  let _fsm: FSM
  let _inbox: IOQueue
  let _program: Program
  let _timer_wheel: Timers
  var _timer_handle: (Timer tag | None) = None

  new create(memory: Array[I64] val, fsm: FSM) =>
    _inbox = IOQueue.create()
    _fsm = fsm
    let send_fn = {(elt: I64)(fsm) => fsm.state_msg(elt)}
    _program = Program.create(_inbox, send_fn, memory)
    _timer_wheel = Timers

  be input(i: I64) => _inbox.put(i)

  be turn_on() =>
    let step_timer = recover StepTimer(this) end
    let timer_handle = Timer(consume step_timer, 5_000, 2_000)
    // Keep the tag around to cancel it in the future
    _timer_handle = recover tag timer_handle end
    _timer_wheel(consume timer_handle)
    _fsm.subscribe(this)

  be step() =>
    _program.step()
    if _program.finished then
      match _timer_handle
      | let t: Timer tag =>
        _fsm.unsubscribe()
        _timer_wheel.cancel(t)
      end
    end

  be turn_off() =>
    _fsm.unsubscribe()
    try _timer_wheel.cancel(_timer_handle as Timer tag) end
