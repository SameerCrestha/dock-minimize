# Developing DockMinimize

Notes for building, signing and releasing DockMinimize. To install it, see the [README](README.md).

## Build

Needs the Xcode Command Line Tools (`xcode-select --install`).

```sh
scripts/run-local.sh     # build, clear the old Accessibility grant, start the app
scripts/build-app.sh     # build build/DockMinimize.app
scripts/make-dmg.sh      # pack it into build/DockMinimize-<version>.dmg
scripts/screenshot.sh    # render the settings window into docs/ for the README
```

Logs:

```sh
/usr/bin/log stream --level info --predicate 'subsystem == "io.github.sameercrestha.dockminimize"'
```

## Signing

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
