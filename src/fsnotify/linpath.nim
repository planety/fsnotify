import xio/linux/inotify
import base
import std/[os, posix]


proc initEventList*(name: string, wd: cint): EventList =
  EventList(name: name, wd: wd)

proc initFile(data: var PathEventData) =
  data.exists = true
  data.name = expandFilename(data.name)
  data.uniqueId = getUniqueFileId(data.name)
  data.wd = inotify_add_watch(data.handle, data.name.cstring, IN_ALL_EVENTS)


proc initFileEventData*(name: string, cb: EventCallback): PathEventData =
  result = PathEventData(kind: PathKind.File)
  result.name = name
  result.handle = inotify_init()
  result.buffer = newString(1024 * 4)
  result.cb = cb

  if fileExists(name):
    initFile(result)

proc initDirEventData*(name: string, cb: EventCallback): PathEventData =
  result = PathEventData(kind: PathKind.Dir)
  result.handle = inotify_init()
  result.buffer = newString(1024 * 4)
  result.cb = cb

  if dirExists(name):
    var event = EventList(name: expandFilename(name))
    event.wd = inotify_add_watch(result.handle, name.cstring, IN_ALL_EVENTS)
    result.list.add event


proc filecb*(data: var PathEventData) =
  if data.exists:
    if fileExists(data.name):
      let size = posix.read(data.handle, data.buffer.cstring, data.buffer.len)
  
      if size > 0:
        var buf = cast[pointer](data.buffer.cstring)
        var events: seq[PathEvent]
        var pos = 0

        while pos < size:
          let event = cast[ptr InotifyEvent](cast[ByteAddress](buf) + pos)
          var name: string
          if event.len != 0:
            name = $(event.name.addr.cstring)
          else:
            name = ""

          if (event.mask and IN_MODIFY) != 0:
            events.add((data.name, FileEventAction.Modify, ""))
          elif (event.mask and IN_DELETE_SELF) != 0:
            events.add((data.name, FileEventAction.Remove, ""))

          inc(pos, sizeof(InotifyEvent) + event.len.int)

        if events.len != 0:
          call(data, events)
    else:
      data.exists = false
      var event = initPathEvent(data.name, FileEventAction.Remove)

      let dir = parentDir(data.name)
      for kind, name in walkDir(dir):
        if kind == pcFile and getUniqueFileId(name) == data.uniqueId:
          data.exists = true
          event = initPathEvent(data.name, FileEventAction.Rename, name)
          data.name = name
          break
      call(data, @[event])
  else:
    if fileExists(data.name):
      initFile(data)
      call(data, @[initPathEvent(data.name, FileEventAction.Create)])

proc dircb*(data: var PathEventData) =
  while true:
    let size = posix.read(data.handle, data.buffer.cstring, data.buffer.len)
    
    if size <= 0:
      break

    var buf = cast[pointer](data.buffer.cstring)
    var events: seq[PathEvent]
    var pos = 0

    var times = 0


    while pos < size:
      inc times
      let event = cast[ptr InotifyEvent](cast[ByteAddress](buf) + pos)
      var name: string
      if event.len != 0:
        name = $(event.name.addr.cstring)
      else:
        name = ""

      if (event.mask and IN_MODIFY) != 0:
        events.add((name, FileEventAction.Modify, ""))
      elif (event.mask and IN_DELETE_SELF) != 0:
        events.add((name, FileEventAction.Remove, ""))
      elif (event.mask and IN_CREATE) != 0:
        events.add((name, FileEventAction.Create, ""))
      elif (event.mask and IN_MOVED_FROM) != 0:
        data.fromName = name
        data.cookie = event.cookie
      elif (event.mask and IN_MOVED_TO) != 0:
        if data.cookie == event.cookie:
          events.add((data.fromName, FileEventAction.Rename, name))
      elif (event.mask and IN_DELETE) != 0:
        events.add((name, FileEventAction.Remove, ""))

      inc(pos, sizeof(InotifyEvent) + event.len.int)


    if events.len != 0:
      call(data, events)
