# fsnotify
A file system monitor in Nim

## Supporting platform

|Platform|Watching Directory|Watching File|
|---|---|---|
|Windows|`ReadDirectoryChangesW` |polling using `os.getLastModificationTime` and `os.fileExists`|
|Linux|`inotify`|polling using `inotify` and `os.fileExists`|
|Macos|TODO(`kqueue`)|polling using `os.getLastModificationTime` and `os.fileExists`|
|BSD|TODO(`kqueue`)|TODO(`kqueue`)|

## Hello, world

```nim
import fsnotify


proc hello(event: seq[PathEvent]) =
  echo "Hello: "
  echo event

var watcher = initWatcher(1)
register(watcher, "/root/play", hello, ms = 100)

while true:
  poll(watcher, 2000)
```
