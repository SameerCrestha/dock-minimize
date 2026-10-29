# DockMinimize

Click an app's Dock icon to minimize it, like the Windows taskbar. Free and open source.

- **App in front, windows open:** click its Dock icon and all its windows minimize together. It uses the app's own Minimize All (⌥⌘M). Apps without it get each window minimized in turn.
- **Windows minimized, or app in the back:** the Dock works as usual, so a click brings back the last window.
- **Hold any modifier key** (⌘ ⌥ ⌃ ⇧) for the normal Dock click, for example to drag an icon.

No menu bar icon. It runs in the background. Open DockMinimize again (Launchpad, Spotlight or Applications) to see its window, where you can:

- check Accessibility access
- turn it off, or start it at login
- exclude apps, so a Dock click on them works as usual
- quit it (closing the window, ⌘Q or Quit in the Dock only close the window)

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

### Signing

macOS ties the Accessibility grant to the app's signature. Builds signed with the same certificate keep the grant across rebuilds and updates. An ad-hoc build loses it every time.

The build script signs with a self-signed "DockMinimize Signing" certificate from `~/.config/dock-minimize/signing.p12` (password in `signing.pass`). It uses a throwaway keychain, so the login keychain is not touched. Without the file it signs ad-hoc, and `run-local.sh` then clears the old grant so you get a fresh prompt.

Keep the .p12 private. Anyone with it could sign an app that inherits DockMinimize's Accessibility grant.

To create one:

```sh
mkdir -p ~/.config/dock-minimize && cd ~/.config/dock-minimize
printf '[req]\ndistinguished_name=dn\nx509_extensions=ext\nprompt=no\n[dn]\nCN=DockMinimize Signing\n[ext]\nbasicConstraints=critical,CA:false\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=critical,codeSigning\n' > cert.cnf
/usr/bin/openssl rand -hex 24 > signing.pass
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config cert.cnf -keyout key.pem -out cert.pem
/usr/bin/openssl pkcs12 -export -inkey key.pem -in cert.pem -name "DockMinimize Signing" -out signing.p12 -passout file:signing.pass
rm cert.cnf key.pem cert.pem && chmod 600 signing.*
```

Logs:

```sh
log stream --level info --predicate 'subsystem == "io.github.sameercrestha.dockminimize"'
```

## Release

Push a version tag. GitHub Actions builds a universal app, signs it with the same certificate, and attaches the `.dmg` to a new release.

The workflow needs two repository secrets (Settings → Secrets and variables → Actions):

- `SIGNING_P12_BASE64`: output of `base64 -i ~/.config/dock-minimize/signing.p12`
- `SIGNING_P12_PASSWORD`: contents of `~/.config/dock-minimize/signing.pass`

```sh
git tag v0.1.0 && git push origin v0.1.0
```

## How it works

A Core Graphics event tap sees each left click. On mouse down it asks the Dock (through the Accessibility API) which icon is under the pointer. If it acts, it swallows the click so the Dock does not undo it.

It presses the app's hidden Minimize All menu item, or sends ⌥⌘M, so every window animates together. Any window that is still open after that gets `kAXMinimizedAttribute` set.

## License

MIT
