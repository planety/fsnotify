import base
import times, os


proc init(data: var PathEventData) =
  data.exists = true
  data.name = expandFilename(data.name)
  data.uniqueId = getUniqueFileId(data.name)
  data.lastModificationTime = getLastModificationTime(data.name)

proc init(data: ptr PathEventData) =
  data.exists = true
  data.name = expandFilename(data.name)
  data.uniqueId = getUniqueFileId(data.name)
  data.lastModificationTime = getLastModificationTime(data.name)

proc initFileEventData*(name: string, cb: EventCallback): PathEventData =
  result = PathEventData(kind: PathKind.File, name: name)
  result.cb = cb

  if fileExists(name):
    init(result)

# proc initFileEventData*(args: seq[tuple[name: string, cb: EventCallback]]): seq[FileEventData] =
#   result = newSeq[FileEventData](args.len)
#   for idx in 0 ..< args.len:
#     result[idx].name = args[idx].name
#     result[idx].cb = args[idx].cb

#     if dirExists(result[idx].name):
#       init(result[idx])

proc close*(data: PathEventData) =
  discard

proc filecb*(args: pointer = nil) =
  if args != nil:
    var data = cast[ptr PathEventData](args)
    if data.exists:
      if fileExists(data.name):
        let now = getLastModificationTime(data.name)
        if now != data.lastModificationTime:
          data.lastModificationTime = now
          call(data, @[initPathEvent(data.name, FileEventAction.Modify)])
      else:
        data.exists = false
        var event = initPathEvent(data.name, FileEventAction.Remove)

        let dir = parentDir(data.name)
        for kind, name in walkDir(dir):
          if kind == pcFile and getUniqueFileId(name) == data.uniqueId:
            data.exists = true
            data.lastModificationTime = getLastModificationTime(name)
            event = initPathEvent(data.name, FileEventAction.Rename, name)
            data.name = name
            break

        call(data, @[event])
    else:
      if fileExists(data.name):
        init(data)
        call(data, @[initPathEvent(data.name, FileEventAction.Create)])


when isMainModule:
  import timerwheel

  proc hello(event: seq[PathEvent]) =
    echo event

  var t = initTimer(100)
  var data = initFileEventData("watch.nim", hello)
  var event0 = initTimerEvent(filecb, cast[pointer](addr data))
  discard t.add(event0, 10, -1)

  while true:
    sleep(2000)
    discard process(t)
