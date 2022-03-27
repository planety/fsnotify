# fsnotify
A file system monitor in Nim

## Supporting platform

|Platform|Watching Directory|Watching File|
|---|---|---|
|Windows|`ReadDirectoryChangesW` |polling using `os.getLastModificationTime` and `os.fileExists`|
|Linux|`inotify`|polling using `inotify` and `os.fileExists`|
|Macos|TODO(`fsevents`)|polling using `os.getLastModificationTime` and `os.fileExists`|
|BSD|Not implemented|TODO(`kqueue`)|

## Hello, world

```nim
import std/os
import fsnotify


proc hello(event: seq[PathEvent]) =
  echo "Hello: "
  echo event

var watcher = initWatcher()
register(watcher, "/root/play", hello)

while true:
  sleep(500)
  process(watcher)
```
