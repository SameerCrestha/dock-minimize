# DockMinimize

Click an app's Dock icon to minimize it, like the Windows taskbar. Free and open source.

- **App in front, windows open:** click its Dock icon and all its windows minimize together. It uses the app's own Minimize All (⌥⌘M). Apps without it get each window minimized in turn.
- **Windows minimized, or app in the back:** the Dock works as usual, so a click brings back the last window.
- **Hold any modifier key** (⌘ ⌥ ⌃ ⇧) for the normal Dock click, for example to drag an icon.

Lives in the menu bar. From there you can turn it off, or start it at login.

## Install

1. Download `DockMinimize-<version>.dmg` from [Releases](../../releases).
2. Open it and drag **DockMinimize** to **Applications**.
3. The first time, right-click the app and choose **Open**. The app is not notarized by Apple, so a double-click is blocked. If macOS still refuses, go to System Settings → Privacy & Security and click **Open Anyway**.
4. Allow it in System Settings → Privacy & Security → **Accessibility**. It needs this to see Dock clicks and minimize windows.

Needs macOS 13 or later. Works on Apple Silicon and Intel.

## Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`).

```sh
scripts/run-local.sh     # build, clear the old Accessibility grant, start the app
scripts/build-app.sh     # build build/DockMinimize.app
scripts/make-dmg.sh      # pack it into build/DockMinimize-<version>.dmg
```

Each ad-hoc build has a new signature, so macOS forgets the Accessibility grant. `run-local.sh` clears the old entry so you get a fresh prompt. To keep the grant across builds, add a self-signed code signing certificate named `DockMinimize Dev` to your login keychain. The build script uses it when present.

Logs:

```sh
log stream --level info --predicate 'subsystem == "io.github.sameercrestha.dockminimize"'
```

## Release

Push a version tag. GitHub Actions builds a universal app and attaches the `.dmg` to a new release.

```sh
git tag v0.1.0 && git push origin v0.1.0
```

## How it works

A Core Graphics event tap sees each left click. On mouse down it asks the Dock (through the Accessibility API) which icon is under the pointer. If it acts, it swallows the click so the Dock does not undo it.

It presses the app's hidden Minimize All menu item, or sends ⌥⌘M, so every window animates together. Any window that is still open after that gets `kAXMinimizedAttribute` set.

## License

MIT
