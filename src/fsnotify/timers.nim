import base

type
  Callback* = proc(args: var PathEventData) {.gcsafe.}

  TimerEvent* = object
    userData*: PathEventData
    cb*: Callback

  Timer* = object
    queue*: seq[TimerEvent]

proc initTimerEvent*(cb: Callback, userData: PathEventData): TimerEvent =
  TimerEvent(cb: cb, userData: userData)

proc initTimer*(): Timer =
  discard

proc add*(timer: var Timer, event: TimerEvent) =
  timer.queue.add(event)

proc execute*(t: var TimerEvent) =
  if t.cb != nil:
    t.cb(t.userData)

proc process*(timer: var Timer) =
  for event in timer.queue.mitems:
    if event.cb != nil:
      event.cb(event.userData)
