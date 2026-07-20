# Squeaky Clean

A small macOS utility that locks your keyboard and trackpad so you can safely wipe down your Mac without triggering random keystrokes, clicks, or app switches.

Hold the spacebar for 3 seconds to unlock.

## Screenshots

![App states](Screenshots/states.jpg 'App states')

## Why

Cleaning a MacBook's keyboard and trackpad with the Mac still on usually means either shutting down entirely, or risking accidental input while you wipe it down, launching apps, typing garbage into whatever's focused, or triggering a screenshot. Squeaky Clean locks input at the system level while you clean, then unlocks itself with a single deliberate gesture once you're done.

## Features

- **Keyboard always locked** while cleaning mode is active, no exceptions
- **Optional trackpad and mouse lock**, toggle it on or off before starting
- **Hold spacebar for 3 seconds to unlock**, the only way out, no accidental early exits
- **Auto-start on launch**, optionally jump straight into cleaning mode when the app opens

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (requested the first time you start cleaning mode, see below)

## Installation

1. Download the latest release from the [Releases](../../releases) page.
2. Unzip and drag `Squeaky Clean.app` into your Applications folder.
3. **First launch**: right-click the app and choose **Open**, then confirm in the dialog that appears. This is a one-time step required because this build isn't distributed through the Mac App Store or signed with a paid Apple Developer certificate.

## Accessibility permission

Squeaky Clean needs Accessibility permission to intercept keyboard and trackpad input system-wide, this is the same category of permission used by tools like window managers and remote-control apps. You'll be prompted the first time you click **Start cleaning**; grant it in **System Settings > Privacy & Security > Accessibility**, then relaunch the app.

**What this permission is, and isn't, used for**: Squeaky Clean only inspects events to detect the spacebar (to know when to unlock) and to decide whether to block or pass through keyboard/mouse input. It does not log, store, transmit, or display any keystrokes, mouse movements, or clicks anywhere, nothing leaves your Mac, and nothing is written to disk.

## Building from source

1. Clone this repo.
2. Open `SqueakyClean.xcodeproj` in Xcode 16 or later.
3. Build and run (`Cmd+R`).

No external dependencies or package managers involved, it's a single Xcode project.

## Known limitations

- Not notarized or signed with a paid Apple Developer certificate, hence the right-click-to-open step on first launch.

## Credits

App icon and in-app illustrations from [Flaticon](https://www.flaticon.com):

- [Cheerful stickers](https://www.flaticon.com/free-stickers/cheerful)
- [Cute stickers](https://www.flaticon.com/free-stickers/cute)
- [Dislike stickers](https://www.flaticon.com/free-stickers/dislike)

## License

The source code in this repository is licensed under the [MIT License](LICENSE).

This does not extend to the app icon or in-app illustrations, those remain under Flaticon's own license terms (see Credits above), separate from the code's MIT license.
