when defined(windows):
  import os, times
  import xio/windows/base/[fileapi, handleapi]
elif defined(linux):
  import posix
elif defined(macosx):
  import posix except Time
  import times


type
  FileEventAction* {.pure.} = enum
    NonAction
    Create, Modify, Rename, Remove
    CreateSelf, RemoveSelf

  PathEvent* = tuple
    name: string
    action: FileEventAction
    newName: string

  EventCallback* = proc (event: seq[PathEvent]) {.gcsafe.}

  PathKind* {.pure.}  = enum
    File, Dir


when defined(windows):
  type
    PathEventData* = object
      name*: string
      exists*: bool
      cb: EventCallback

      case kind*: PathKind
      of PathKind.File:
        lastModificationTime*: Time
        uniqueId*: uint64
      of PathKind.Dir:
        handle*: Handle
        buffer*: string
        reads*: DWORD
        over*: OVERLAPPED

  proc close*(data: PathEventData) =
    case data.kind
    of PathKind.File:
      discard
    of PathKind.Dir:
      discard data.handle.closeHandle()

  proc getFileId(name: string): uint =
    var x = newWideCString(name)
    result = uint getFileAttributesW(addr x)
    result = uint getFileAttributesW(cast[LPCWSTR](addr x))

  proc `name=`*(data: var PathEventData, name: string) =
    data.name = name

  proc `cb=`*(data: var PathEventData, cb: EventCallback) =
    data.cb = cb

  proc call*(data: var PathEventData, event: seq[PathEvent]) =
    data.cb(event)

elif defined(linux):
  type
    EventList* = object
      name*: string
      wd*: cint

    PathEventData* = object
      handle*: FileHandle
      buffer*: string
      cb*: EventCallback

      case kind*: PathKind
      of PathKind.File:
        name*: string
        wd*: cint
        exists*: bool
        uniqueId*: uint64
      of PathKind.Dir:
        list*: seq[EventList]
        fromName*: string
        cookie*: uint32


  proc call*(data: var PathEventData, event: seq[PathEvent]) =
    if data.cb != nil:
      data.cb(event)

elif defined(macosx):
  type
    PathEventData* = object
      name*: string
      exists*: bool
      cb: EventCallback

      case kind*: PathKind
      of PathKind.File:
        lastModificationTime*: Time
        uniqueId*: uint64
      of PathKind.Dir:
        discard

  proc close*(data: PathEventData) =
    case data.kind
    of PathKind.File:
      discard
    else:
      discard

  proc `name=`*(data: var PathEventData, name: string) =
    data.name = name

  proc `cb=`*(data: var PathEventData, cb: EventCallback) =
    data.cb = cb

  proc call*(data: var PathEventData, event: seq[PathEvent]) =
    data.cb(event)

proc initPathEvent*(name: string, action: FileEventAction, newName = ""): PathEvent =
  (name, action, newName)

proc getUniqueFileId*(name: string): uint64 =
  when defined(windows):
    let 
      tid = getCreationTime(name)
      id = getFileId(name)
    result = uint64(toWinTime(tid)) xor id
  elif defined(posix):
    var s: Stat
    if stat(name, s) == 0:
      result = uint64(s.st_dev or s.st_ino shl 32)
