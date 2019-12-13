use "package:../07"
use "time"

actor ProgramActor is Executor
  let _robot: Robot
  let _inbox: IOQueue
  let _program: Program
  let _timer_wheel: Timers
  var _timer_handle: (Timer tag | None) = None

  new create(memory: Array[I64] val, robot: Robot) =>
    _inbox = IOQueue.create()
    _robot = robot
    let send_fn = {(elt: I64)(robot) => robot.state_msg(elt)}
    _program = Program.create(_inbox, send_fn, memory)
    _timer_wheel = Timers

  be input(i: I64) => _inbox.put(i)

  be turn_on() =>
    let step_timer = recover StepTimer(this) end
    let timer_handle = Timer(consume step_timer, 5_000, 2_000)
    // Keep the tag around to cancel it in the future
    _timer_handle = recover tag timer_handle end
    _timer_wheel(consume timer_handle)
    _robot.subscribe(this)

  be step() =>
    _program.step()
    if _program.finished then
      match _timer_handle
      | let t: Timer tag =>
        _robot.unsubscribe()
        _timer_wheel.cancel(t)
      end
    end
