import xio/windows/base/[fileapi, winbase, ioapiset]
import os
import base


proc startQueue*(data: var PathEventData) =
  discard readDirectoryChangesW(data.handle, data.buffer.cstring, 
              cast[DWORD](data.buffer.len), 0, FILE_NOTIFY_CHANGE_FILE_NAME or 
              FILE_NOTIFY_CHANGE_DIR_NAME or 
              FILE_NOTIFY_CHANGE_LAST_WRITE, data.reads, addr data.over, nil)


proc init(data: var PathEventData) =
  let name = newWideCString(data.name)
  data.name = expandFilename(data.name)
  data.exists = true
  data.buffer = newString(1024)
  data.handle = createFileW(name, FILE_LIST_DIRECTORY, FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                              OPEN_EXISTING, FILE_FLAG_OVERLAPPED or FILE_FLAG_BACKUP_SEMANTICS, nil)
  startQueue(data)

proc initDirEventData*(name: string, cb: EventCallback): PathEventData =
  result = PathEventData(kind: PathKind.Dir, name: name)
  result.cb = cb

  if dirExists(name):
    init(result)

# proc initDirEventData*(args: seq[tuple[name: string, cb: EventCallback]]): seq[DirEventData] =
#   result = newSeq[DirEventData](args.len)
#   for idx in 0 ..< args.len:
#     result[idx].name = args[idx].name
#     result[idx].cb = args[idx].cb

#     if dirExists(result[idx].name):
#       init(result[idx])

proc dircb*(data: var PathEventData) =
  if data.exists:
    if dirExists(data.name):
      if data.handle == nil:
        let name = newWideCString(data.name)
        data.handle = createFileW(name, FILE_LIST_DIRECTORY, FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                            OPEN_EXISTING, FILE_FLAG_OVERLAPPED or FILE_FLAG_BACKUP_SEMANTICS, nil)


      var event: seq[PathEvent]
      for _ in 0 ..< 2:
        if getOverlappedResult(data.handle, addr data.over, data.reads, 0) != 0:
          var buf = cast[pointer](data.buffer.substr(0, data.reads.int - 1).cstring)
          var oldName = ""
          var next: int

          while true:
            let info = cast[PFILE_NOTIFY_INFORMATION](cast[ByteAddress](buf) + next)

            if info == nil:
              break

            ## TODO reduce copy
            var tmp = newWideCString("", info.FileNameLength.int div 2)
            for idx in 0 ..< info.FileNameLength.int div 2:
              tmp[idx] = info.FileName[idx]

            let name = $tmp

            case info.Action
            of FILE_ACTION_ADDED:
              event.add(initPathEvent(name, FileEventAction.Create))
            of FILE_ACTION_REMOVED:
              event.add(initPathEvent(name,FileEventAction.Remove))
            of FILE_ACTION_MODIFIED:
              event.add(initPathEvent(name, FileEventAction.Modify))
            of FILE_ACTION_RENAMED_OLD_NAME:
              oldName = name
            of FILE_ACTION_RENAMED_NEW_NAME:
              event.add(initPathEvent(oldName, FileEventAction.Rename, name))
            else:
              discard

            if info.NextEntryOffset == 0:
              break

            inc(next, info.NextEntryOffset.int)

          call(data, event)
        startQueue(data)
        
    else:
      data.exists = false
      data.handle = nil
      call(data, @[initPathEvent("", FileEventAction.RemoveSelf)])

  else:
    if dirExists(data.name):
      init(data)
      call(data, @[initPathEvent("", FileEventAction.CreateSelf)])
