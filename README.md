# DockMinimize

**A free macOS app: click the Dock icon of the app you are using, and its windows minimize.** Like the taskbar on Windows.

<p align="center">
  <a href="https://github.com/SameerCrestha/dock-minimize/releases/latest/download/DockMinimize.dmg"><img src="https://img.shields.io/badge/Download_for_macOS-0A84FF?style=for-the-badge&logo=apple&logoColor=white" alt="Download for macOS"></a>
</p>
<p align="center">macOS 13 or later · Apple Silicon and Intel · Free and open source</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
    <img src="docs/settings-light.png" alt="DockMinimize settings window" width="480">
  </picture>
</p>

## Why I made it

On Windows you click an app in the taskbar to tuck it away. On a Mac, clicking the Dock icon of the app in front does nothing.

The apps that add this either cost money, like Click2Minimize, or bundle it with a lot more: window previews, app switchers, gestures, snapping. I wanted one small change to the Dock, for free, and nothing else.

So DockMinimize:

- changes one click and leaves the rest of the Dock alone
- has no menu bar icon, no account and no tracking. Its only network use is a daily check for a new version.
- is about 500 lines of Swift you can read in one sitting

## What it does

- **Click the Dock icon of the app in front:** all its windows minimize together. It uses the app's own Minimize All (⌥⌘M), so they animate at the same time. Apps without Minimize All get each window minimized in turn.
- **Every other click works as usual.** Click an app in the back to switch to it. Click an app whose windows are minimized and macOS brings the last one back.
- **Hold any modifier key** (⌘ ⌥ ⌃ ⇧) for the normal Dock click, for example to drag an icon.
- **Exclude apps** that should keep the normal click.

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
That is what macOS does. DockMinimize only changes the click that minimizes, and leaves bringing windows back to the Dock.

**An app minimizes its windows one by one.**
That app has no Minimize All, so DockMinimize minimizes each window itself. Add it to Excluded apps if you prefer the normal click there.

**Does it work with "Minimize windows into application icon"?**
Yes, with that setting on or off.

## Building it yourself

See [DEVELOPMENT.md](DEVELOPMENT.md).

## License

MIT
