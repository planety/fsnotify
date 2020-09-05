import ../../src/fsnotify





block:
  var count = 0

  proc modify(event: seq[PathEvent]) =
    var s: set[FileEventAction] = {}
    for e in event:
      s.incl e.action

    doAssert FileEventAction.Modify in s
    inc count

  var watcher = initWatcher(1)
  let filename = "tests/static/go_test1.txt"
  
  register(watcher, filename, modify, ms = 10)

  writeFile(filename, "1234")
  poll(watcher, 20)
  doAssert count == 1
