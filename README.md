# DockMinimize

<p align="center">
  <a href="https://github.com/SameerCrestha/dock-minimize/releases/latest/download/DockMinimize.dmg"><img src="https://img.shields.io/github/v/release/SameerCrestha/dock-minimize?style=for-the-badge&label=Download%20for%20macOS&logo=apple&logoColor=white&color=0A84FF" alt="Download for macOS"></a>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple_Silicon_%2B_Intel-0A84FF?style=flat-square" alt="Apple Silicon and Intel">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-0A84FF?style=flat-square" alt="MIT license"></a>
</p>

<p align="center">
  <em><strong>Click to minimize for macOS.</strong> Click an app's icon in the Dock and its windows minimize, like the taskbar on Windows. A small Swift app with no menu bar icon and no tracking.</em>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
    <img src="docs/settings-light.png" alt="DockMinimize settings window" width="480">
  </picture>
</p>

## What it does

When you click the Dock icon of the app you are already using, macOS does nothing: the app is already active, so the click has no job. DockMinimize gives it one: minimize the app's windows.

- Click the app you are **using** → its windows minimize.
- Click **another app** → macOS as usual: it comes to the front.
- Click an app whose windows are **all minimized** → macOS as usual: the last window comes back.
- Click a **folder, the Trash or Launchpad** → macOS as usual.
- Hold **⌘ ⌥ ⌃ or ⇧** while clicking → macOS as usual, for example to drag an icon.
- Apps in **Excluded apps** → macOS as usual.

## Multiple windows

- **All at once.** Every open window of the app goes down in one animation. DockMinimize uses the app's own **Minimize All**, the same as pressing ⌥⌘M or Option-clicking the yellow button.
- **Apps without Minimize All.** DockMinimize minimizes each window itself, so they go down one after another.
- **Some open, some minimized.** The open ones minimize. The rest stay where they are.
- **Full screen.** Full-screen windows are left alone. If the app only has full-screen windows, the click works as usual.
- **Getting them back.** Click the icon again and the last window comes back, as macOS always does. Click a window's thumbnail in the Dock for the others. If you use "Minimize windows into application icon", right-click the app's icon and pick a window.

## Highlights

| | |
|---|---|
| **One click changed** | The rest of the Dock works as before. |
| **Windows go down together** | Uses the app's own Minimize All, not one window at a time. |
| **No menu bar icon** | Runs in the background. Open the app to see its window. |
| **No tracking** | The only network use is a daily check for a new version on GitHub. |
| **Updates itself** | One click to install, or fully automatic. The update's signature is checked first. |
| **Keeps its access** | Every release is signed with the same certificate, so updates keep Accessibility access. |
| **Starts at login** | On by default, one switch to turn it off. |
| **MIT license** | Use it, change it and share it, at home or at work. |

## Why I made it

On Windows you click an app in the taskbar to tuck it away. On a Mac that click does nothing.

The apps that add this either come with strings attached (a price, or a license that rules out use at work), or bundle it with a lot more: window previews, app switchers, gestures, snapping. I wanted one small change to the Dock and nothing else. DockMinimize is about 700 lines of Swift you can read in one sitting.

## Install

Needs macOS 13 or later, on Apple Silicon or Intel.

1. Click **Download for macOS** at the top, or get `DockMinimize.dmg` from the [latest release](https://github.com/SameerCrestha/dock-minimize/releases/latest).
2. Open it and drag **DockMinimize** to **Applications**.
3. Open DockMinimize from Applications. The first time, macOS blocks it with "Apple could not verify…". This is because the app is not notarized, which needs a paid Apple developer account.
   - Click **Done**.
   - Go to System Settings → **Privacy & Security**, scroll down, and click **Open Anyway** next to DockMinimize.
   - Confirm with **Open Anyway** and your password. You only do this once.
4. The DockMinimize window opens. Under **Access**, click **Open Accessibility Settings** and switch **DockMinimize** on. The window turns green.
5. That's it. Close the window and DockMinimize keeps working. It also starts at login.

## Use

- Open DockMinimize again (Launchpad, Spotlight or Applications) to see its window. From there you can:
  - check Accessibility access
  - turn it off, or stop it starting at login (on by default)
  - check for updates
  - exclude apps
  - quit it
- Closing the window, ⌘Q or Quit in the Dock only close the window. DockMinimize keeps working.
- The **Quit DockMinimize** button closes it and stops it completely, until you open it again or log in.

## Update

DockMinimize checks GitHub for a new version once a day. When one is out, you get a notification.

- Open DockMinimize and click **Install**. It downloads the update, checks it is signed by the same developer, replaces itself and restarts. Accessibility access stays on.
- Or switch on **Install updates automatically** and skip the click.
- Or download the new `DockMinimize.dmg` yourself and replace the app in Applications.

If the window says it needs access while the switch is already on, select DockMinimize in the Accessibility list, click **−**, then **+** to add it again.

## Uninstall

1. Open DockMinimize and click **Quit DockMinimize**.
2. Drag it from Applications to the Trash.
3. Optional: remove it from System Settings → Privacy & Security → **Accessibility**, and from General → **Login Items**.

## FAQ

**Why does it need Accessibility access?**
To see which Dock icon you clicked, and to minimize windows. Nothing about your windows or clicks leaves your Mac.

**Does it connect to the internet?**
Only to check GitHub for a new version once a day, and to download an update when you install one.

**Why does a second click bring back only one window?**
That is what macOS does. DockMinimize only changes the click that minimizes, and leaves bringing windows back to the Dock. See [Multiple windows](#multiple-windows).

**An app minimizes its windows one by one.**
That app has no Minimize All. See [Multiple windows](#multiple-windows). Add it to Excluded apps if you prefer the normal click there.

**Does it work with "Minimize windows into application icon"?**
Yes, with that setting on or off.

## Building it yourself

See [DEVELOPMENT.md](DEVELOPMENT.md).

## License

MIT
