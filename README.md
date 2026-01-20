<p align="center">
  <img width="256" src="https://raw.githubusercontent.com/Medvedev91/Option1/refs/heads/main/Misc/Readme/AppIcon1024.png">
</p>

# Option1 - Pragmatic Window Manager for macOS

The idea - binding shortcuts like `⌥-1`, `⌥-2` to windows you need.

Press `⌥-1` to open Safari, `⌥-2` to open Calendar. Customize it.

<p align="left">
  <img width="512" src="https://raw.githubusercontent.com/Medvedev91/Option1/refs/heads/main/Misc/Readme/basics.png">
</p>

## Windows

Feature to manage apps with multiple open windows. Like multiple open Word documents or Xcode projects.

Let's say we have two windows for one app, like two Xcode projects. We cannot open the window we need with built-in `⌘-Tab` because macOS opens apps, not windows. Let's solve this with Option1.

Look at the screenshot:

- for `⌥-3` I bind `Xcode` with `Option1` title substring,
- for `⌥-4` I bind `Xcode` with `timeto.me` title substring.

This means `⌥-3` opens Xcode window with `Option1` in the title, and `⌥-4` with `timeto.me`. Solved!

<p align="left">
  <img width="1024" src="https://raw.githubusercontent.com/Medvedev91/Option1/refs/heads/main/Misc/Readme/windows.png">
</p>

## Workspaces

Feature to setup sets of shortcuts for different projects.

I work on two projects: `Option1` and `timeto.me`. I got used to press `⌥-3` to open `Xcode`. It means when I work on `Option1` I want `⌥-3` opens `Xcode - Option1`, but when I work on `timeto.me` I want the same `⌥-3` but opens `Xcode - timeto.me`.

In addition, for each project, I want `⌥-4` opens the right `IntelliJ IDEA` window.

<!--
I work on two projects: `Option1` and `timeto.me`. For each project, I use two apps: `Xcode` and `IntelliJ IDEA`. I got used to press `⌥-3` to `Xcode` and `⌥-4` to `IntelliJ IDEA`. It means when I work on `Option1` I want `⌥-3` opens `Xcode - Option1`, but when I work on `timeto.me` I want the same `⌥-3` but opens `Xcode - timeto.me`.
-->

This is how I setup two workspaces:

<p align="left">
  <img width="700" src="https://raw.githubusercontent.com/Medvedev91/Option1/refs/heads/main/Misc/Readme/workspaces.png">
</p>

To switch between workspaces, use menu bar.

<p align="left">
  <img width="512" src="https://raw.githubusercontent.com/Medvedev91/Option1/refs/heads/main/Misc/Readme/menu.png">
</p>

<!--

## Other Features

- Supports multiple displays ✅
- Supports built-in macOS desktops ✅
- Supports full screen windows ✅

-->

<!--

## My Personal Advice 

I call it pragmatic because I focus on the features I miss in macOS. It is not a replacement but an addition to the built-in macOS window management.

todo

-->

## Download

https://option1.io/Option1.dmg

## Thanks

https://github.com/lwouis/alt-tab-macos

https://github.com/soffes/HotKey

https://github.com/sparkle-project/Sparkle

https://github.com/sindresorhus/create-dmg

https://github.com/Alamofire/Alamofire
