import kqueue, posix

when false:
  type
    KEvent = object
      ident*: uint                 ## identifier for this event  (uintptr_t)
      filter*: cshort              ## filter for event
      flags*: cushort              ## general flags
      fflags*: cuint               ## filter-specific flags
      data*: int                   ## filter-specific data  (intptr_t)
      udata*: pointer              ## opaque user data identifier


  proc kqueue(): cint
   {.importc: "kevent",
    header: "<sys/event.h>".}

  proc kevent(kqFD: cint; changelist: ptr KEvent; nchanges: cint; eventlist: ptr KEvent;
           nevents: cint; timeout: ptr Timespec): cint

  proc EV_SET(event: ptr KEvent; ident: uint; filter: cshort; flags: cushort; fflags: cuint;
           data: int; udata: pointer)


let fd = kqueue()
if fd < 0:
  doAssert false, "fd"

var eventsToMonitor: KEvent
var eventData: KEvent
var eventfd = open("test.txt")

when defined(windows):
  const EVFILT_VNODE = -4
const 
  filter = EVFILT_VNODE
  flags = EV_ADD or EV_CLEAR
  fflags = NOTE_DELETE or NOTE_EXTEND or NOTE_RENAME or NOTE_WRITE


EV_SET(addr eventsToMonitor, cast[uint](eventfd), filter, flags, fflags, 0, nil)

# let res = kevent



