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
    try:
      init(result)
    except OSError:
      # File was removed between fileExists check and init call
      discard

# proc initFileEventData*(args: seq[tuple[name: string, cb: EventCallback]]): seq[FileEventData] =
#   result = newSeq[FileEventData](args.len)
#   for idx in 0 ..< args.len:
#     result[idx].name = args[idx].name
#     result[idx].cb = args[idx].cb

#     if dirExists(result[idx].name):
#       init(result[idx])

proc close*(data: PathEventData) =
  discard

proc filecb*(data: var PathEventData) =
  if data.exists:
    if fileExists(data.name):
      try:
        let now = getLastModificationTime(data.name)
        if now != data.lastModificationTime:
          data.lastModificationTime = now
          call(data, @[initPathEvent(data.name, FileEventAction.Modify)])
      except OSError:
        # File was removed between fileExists check and getLastModificationTime call
        discard
    else:
      data.exists = false
      var event = initPathEvent(data.name, FileEventAction.Remove)

      let dir = parentDir(data.name)
      for kind, name in walkDir(dir):
        if kind == pcFile and getUniqueFileId(name) == data.uniqueId:
          data.exists = true
          try:
            data.lastModificationTime = getLastModificationTime(name)
          except OSError:
            # File was removed between walkDir and getLastModificationTime call
            data.exists = false
            continue
          event = initPathEvent(data.name, FileEventAction.Rename, name)
          data.name = name
          break

      call(data, @[event])
  else:
    if fileExists(data.name):
      try:
        init(data)
        call(data, @[initPathEvent(data.name, FileEventAction.Create)])
      except OSError:
        # File was removed between fileExists check and init call
        discard
