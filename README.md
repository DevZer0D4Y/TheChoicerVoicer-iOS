# The Choicer Voicer for iOS

An unofficial iPhone and iPad port of **[The Choicer Voicer](https://yeahmaybe.itch.io/the-choicer-voicer)**, YeahMaybe's voice-matching party game made with Godot 4. The app is a patched Godot 4.4.1 engine for iOS that runs the game from **your own copy** of it: you buy the game on itch.io, copy its Windows `.exe` into the app's folder, and the app plays it with working microphone input, touch controls and full-screen display.

**The game is not included.** This repository and its IPA contain only the engine patches, a small launcher screen, iOS layout fixes and the build script. Buy the game from [YeahMaybe on itch.io](https://yeahmaybe.itch.io/the-choicer-voicer) to play.

**[Releases](https://github.com/DevZer0D4Y/TheChoicerVoicer-iOS/releases)** · [Changelog](CHANGELOG.md)

If you want to support me and remain up-to-date about this and other projects, you can in different ways:

Ko-Fi: https://ko-fi.com/dev_zer0

Discord: https://discord.gg/uFChheZEWX

YouTube: https://www.youtube.com/@develop_erZ

## Features

- Runs the Windows release of The Choicer Voicer from its `.exe`, with no conversion step: the game data is read straight from the file.
- Microphone input that works on iOS. Stock Godot 4.4 can't record on iPhone; the port backports the fix from Godot 4.5 and asks for microphone access at launch.
- Full screen on every iPhone and iPad shape, in either landscape orientation. Dub mode's TV and remote keep their PC layout, and pack videos keep their proportions instead of stretching.
- Touch controls: a tap is a left click, a two-finger tap is a right click (for example, to skip dialogue).
- Voice, player, studio, judge, host and menu packs in the app's folder in the Files app, so you can add your own packs without a computer. The game's "open folder" buttons open that folder in Files.
- Game audio from the loudspeaker while the microphone is on, and alongside other apps' audio.

## Requirements

- An iPhone or iPad running **iOS/iPadOS 15 or later**. Development and playtesting have used an **iPhone 16 Pro Max**.
- The Windows version of **The Choicer Voicer**, bought from [itch.io](https://yeahmaybe.itch.io/the-choicer-voicer). Any version made with Godot 4.0 to 4.4 works; 0.5.1 has been tested.
- A sideloading tool to sign and install the IPA, such as ESign, AltStore, SideStore or Sideloadly.

## Installation

1. Obtain the IPA from a [release](https://github.com/DevZer0D4Y/TheChoicerVoicer-iOS/releases) or [build it from source](#building).
2. Sign and install it with your preferred sideloading tool. With ESign, import the IPA, then sign and install it inside ESign.
3. Open **The Choicer Voicer**. Without the game, it shows how to add it.

To update an existing installation, use the same signing identity and bundle identifier (`com.devz.thechoicervoicer`) to keep your packs and saves.

### Adding the game

1. Download the Windows version from your itch.io library and unzip it. The Files app unzips a `.zip` when you tap it.
2. Copy the game's `.exe` (for example `TheChoicerVoicer_0-5-1 stable.exe`) into **Files → On My iPhone → The Choicer Voicer**. The launcher's **Open the app's folder** button opens it.
3. Close the app completely by swiping it away in the app switcher, then open it again.
4. Allow microphone access when iOS asks.

To change versions, replace the `.exe`. If the folder holds a `.pck`, it is used before any `.exe`.

### Packs and saves

The app's folder is in **Files → On My iPhone → The Choicer Voicer**:

```text
The Choicer Voicer/
├── <the game>.exe      Your copy of the game
├── override.cfg        iOS settings, rewritten at each launch
└── game/
    ├── packs_voice/    Voice packs: one folder of clips per pack
    ├── packs_player/   Player packs
    ├── packs_studio/   Studio packs
    ├── packs_judges/   Judge packs
    ├── packs_host/     Host packs
    ├── packs_menu/     Menu packs
    ├── recordings/     Your recordings
    └── saves/          Save data and settings
```

Copy a pack's folder into the matching `packs_` folder, then reopen the game. On macOS, skip the hidden `._` files that copying from external drives can create.

## Playing

| Desktop | iPhone and iPad |
|---|---|
| Left click | Tap |
| Right click | Two-finger tap |
| Microphone | The device microphone, or a connected headset |

## How it works

The app is Godot 4.4.1, the engine version the game is made with, built for iOS with four patches in [`engine/`](engine/):

- [`0001-ios-microphone-input.patch`](engine/0001-ios-microphone-input.patch): fixes microphone input on iOS (from Godot 4.5, [godotengine/godot#107973](https://github.com/godotengine/godot/pull/107973)) and requests microphone access, starting the input once it is granted.
- [`0002-ios-load-game-from-documents.patch`](engine/0002-ios-load-game-from-documents.patch): at launch, finds a game `.exe` or `.pck` in the app's Documents folder, checks that it holds a pack this engine can open, and boots it as the main pack. Windows exports of Godot games carry their game data appended to the `.exe`, which the engine reads directly. iOS settings go in `override.cfg` next to it, and the app's own pack is mounted alongside the game for the layout fixes.
- [`0003-ios-two-finger-right-click.patch`](engine/0003-ios-two-finger-right-click.patch): turns a second finger into the right mouse button.
- [`0004-ios-open-folders-in-files.patch`](engine/0004-ios-open-folders-in-files.patch): opens folder paths in the Files app.

The [launcher](launcher/) runs when there is no game file and explains how to add one, naming any file it couldn't use. Its [`ios_port/port_fixes.gd`](launcher/ios_port/port_fixes.gd) runs alongside the game: the game is laid out for 16:9 screens, so on wider ones it keeps dub mode's TV and remote at their PC layout and draws pack videos at their own aspect ratio.

## Building

Needs macOS with Xcode, [SCons](https://scons.org) and the [Godot 4.4.1 editor](https://github.com/godotengine/godot/releases/tag/4.4.1-stable).

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot ios/build.sh
```

The release IPA uses Godot's default icon, since the game's icon is part of the game. To give your build the game's own icon, pass your copy of the game, and the script takes the icon from it:

```sh
GAME_EXE="/path/to/TheChoicerVoicer_0-5-1 stable.exe" GODOT=/Applications/Godot.app/Contents/MacOS/Godot ios/build.sh
```

`ICON=/path/to/icon.svg` (or a 1024×1024 `.png`) uses any other image instead.

The script clones Godot 4.4.1, applies the patches, builds the iOS engine, packs it into Godot's official iOS export template, exports the launcher and builds an unsigned `ios/build/TheChoicerVoicer-iOS.ipa`. The first build takes about 25 minutes and 4 GB of disk.

Godot 4.4 predates the UIScene app lifecycle that iOS 27 requires of apps built with its SDK, so the script stamps the app with an older SDK version to keep it on the legacy lifecycle.

## Known issues

- Godot's Mobile renderer, used on iOS, has no VoxelGI, so the 3D studio's lighting is flatter than on PC.
- Versions of the game made with Godot 4.5 or later won't load until the port moves to a newer engine; the launcher says so.

## Credits

- **The Choicer Voicer** by [YeahMaybe](https://yeahmaybe.itch.io). All rights to the game belong to its developer.
- **[Godot Engine](https://godotengine.org)**, MIT license.
- App icon: Godot's default project icon, based on the Godot logo by Andrea Calabró, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Unofficial fan project, not affiliated with or endorsed by YeahMaybe. It contains no part of the game; please buy the game to support its developer. This port must not be sold.
