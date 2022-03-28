import base
import filepoll
export filepoll


proc initDirEventData*(name: string, cb: EventCallback): PathEventData =
  discard

proc dircb*(data: var PathEventData) =
  discard
