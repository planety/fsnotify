type
  Callback* = proc(args: pointer = nil) {.gcsafe.}

  TimerEvent* = object
    userData*: pointer
    cb*: Callback

  Timer* = object
    queue*: seq[TimerEvent]

proc initTimerEvent*(cb: Callback, userData: pointer = nil): TimerEvent =
  TimerEvent(cb: cb, userData: userData)

proc initTimer*(): Timer =
  discard

proc add*(timer: var Timer, event: TimerEvent) =
  timer.queue.add(event)

proc execute*(t: TimerEvent) =
  if t.cb != nil:
    t.cb(t.userData)

proc process*(timer: var Timer) =
  for event in timer.queue:
    if event.cb != nil:
      event.cb(event.userData)
