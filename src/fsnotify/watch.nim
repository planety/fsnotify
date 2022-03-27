import timers
import os, base
export base


when defined(windows):
  import windir, filepoll
  export windir, filepoll
elif defined(linux):
  import linpath
  export linpath
elif defined(macosx):
  import macpath
  export macpath

type
  Watcher* = object
    timer: Timer
    path: seq[PathEventData]


proc initWatcher*(): Watcher =
  discard

proc register*(watcher: var Watcher, path: string, cb: EventCallback, 
               treatAsFile = false) =
  let idx = watcher.path.len

  let pathData =
    if fileExists(path):
      initFileEventData(path, cb)
    elif dirExists(path):
      initDirEventData(path, cb)
    elif treatAsFile:
      initFileEventData(path, cb)
    else:
      initDirEventData(path, cb)

  watcher.path.add pathData


  case pathData.kind
  of PathKind.File:
    var event = initTimerEvent(filecb, cast[pointer](addr watcher.path[idx]))
    watcher.timer.add(event)
  of PathKind.Dir:
    var event = initTimerEvent(dircb, cast[pointer](addr watcher.path[idx]))
    watcher.timer.add(event)

proc register*(watcher: var Watcher, pathList: seq[string], cb: EventCallback,
               treatAsFile = false) =
  for path in pathList:
    watcher.register(path, cb, treatAsFile)

template process*(watcher: var Watcher) =
  process(watcher.timer)

proc poll*(watcher: var Watcher, ms = 100) =
  sleep(ms)
  process(watcher)

when isMainModule:
  block:
    proc hello(event: seq[PathEvent]) =
      echo "Hello: "
      echo event

    var watcher = initWatcher()
    register(watcher, "/root/play", hello)

    while true:
      poll(watcher, 300)

# when isMainModule:
#   block:
#     var count = 0
#     proc hello(event: PathEvent) =
#       inc count

#     let filename = "d://qqpcmgr/desktop/e.txt"
#     var data = initFileEventData(filename, cb = hello)
#     var watcher = initWatcher(1)
#     register(watcher, data)

#     writeFile(filename, "123")
#     poll(watcher, 10)

#     doAssert watcher.taskCounter == 1
#     doAssert count == 1

#     moveFile(filename, "d://qqpcmgr/desktop/1223.txt")
#     poll(watcher, 10)
#     doAssert watcher.taskCounter == 1
#     doAssert count == 2

#     remove(watcher, data)
#     poll(watcher, 10)
#     doAssert watcher.taskCounter == 0
#     doAssert count == 2

#   block:
#     let path = "d://qqpcmgr/desktop/test"
#     var data = initDirEventData(path)
#     var watcher = initWatcher(100)
#     register(watcher, data)

#     while true:
#       poll(watcher, 2000)
#       echo data.getEvent()
