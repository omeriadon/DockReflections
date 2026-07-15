<img width="300" height="300" alt="Dock Reflections-iOS-Default-1024@1x" src="https://github.com/user-attachments/assets/4c5a4072-4c4e-4774-8cc2-17dc846796df" />

# Dock Reflections

> [!WARNING]
> You must disable SIP and Library Vaildation to run this, and you need Ammonia installed. Do not attempt running this unless you know what you are doing and the risks involved.

> [!NOTE]
> This app only runs on macOS 26.6 and later, since the features this app exposes are only possible due to the transparency of Liquid Glass and its refractive effects.

---

Dock Reflecctions is an experimental Ammonia tweak for macOS that adds icon reflections beneath the Dock and replaces the standard running-app indicators with configurable glowing indicators.

Ammonia is a modern macOS tweak loader and code injection engine, allowing you to change parts of macOS that aren't normally changeable, in this case the Dock.

Before:
<img width="3254" height="194" alt="SCR-20260715-pevo" src="https://github.com/user-attachments/assets/7b6414a0-ae16-4a4d-b257-5b338bd1177a" />
After:
<img width="3294" height="202" alt="SCR-20260715-pexq" src="https://github.com/user-attachments/assets/22ee84b8-a838-4ea3-9307-6798ab9ecb10" />

<br/>

The tweak currently targets Apple Silicon and relies on private Dock implementation details. System updates can change those details.

<br/>

## Requirements

- Apple Silicon Mac
- Ammonia
- Xcode Command Line Tools

## Build and install

```sh
make clean deploy
```

The tweak installs to `/var/ammonia/core/tweaks` and restarts Dock.

## Settings app

The native macOS settings app in [`SettingsApp`](SettingsApp) exposes every option and includes a Restart Dock button. Open `SettingsApp/DockReflectionsSettings.xcodeproj` in Xcode and run the `DockReflectionsSettings` scheme, or grab the latest version from Releases.

<br/>

## Configuration

Changes take effect after Dock restarts.

###### Reflections enabled — `true`

```sh
defaults write com.omeriadon.DockReflections enabled -bool true
```

###### Reflection scale — `0.90`

```sh
defaults write com.omeriadon.DockReflections reflectionScale -float 0.90
```

###### Reflection vertical offset — `-5`

```sh
defaults write com.omeriadon.DockReflections reflectionYOffset -float -5
```

###### Reflection opacity — `1.0`

```sh
defaults write com.omeriadon.DockReflections reflectionOpacity -float 1.0
```

###### Reflection blur radius — `0`

```sh
defaults write com.omeriadon.DockReflections reflectionBlurRadius -float 0
```

###### Reflect folders — `false`

```sh
defaults write com.omeriadon.DockReflections reflectFolders -bool false
```

###### Reflect Trash — `false`

```sh
defaults write com.omeriadon.DockReflections reflectTrash -bool false
```

---

###### Indicators enabled — `true`

```sh
defaults write com.omeriadon.DockReflections indicatorsEnabled -bool true
```

###### Indicator width — `12`

```sh
defaults write com.omeriadon.DockReflections indicatorWidth -float 12
```

###### Indicator height — `6`

```sh
defaults write com.omeriadon.DockReflections indicatorHeight -float 6
```

###### Indicator corner radius — `3`

```sh
defaults write com.omeriadon.DockReflections indicatorCornerRadius -float 3
```

###### Indicator vertical offset — `-4`

```sh
defaults write com.omeriadon.DockReflections indicatorYOffset -float -4
```

###### Indicator opacity — `1.0`

```sh
defaults write com.omeriadon.DockReflections indicatorOpacity -float 1.0
```

###### Indicator blur radius — `24`

```sh
defaults write com.omeriadon.DockReflections indicatorBlurRadius -float 24
```

###### Indicator transition blur radius — `16`

```sh
defaults write com.omeriadon.DockReflections indicatorTransitionBlurRadius -float 16
```

###### Indicator glow opacity — `1.0`

```sh
defaults write com.omeriadon.DockReflections indicatorGlowOpacity -float 1.0
```

###### Indicator glow layers — `6`

```sh
defaults write com.omeriadon.DockReflections indicatorGlowLayers -int 6
```

###### Indicator entry duration — `0.28`

```sh
defaults write com.omeriadon.DockReflections indicatorEntryDuration -float 0.28
```

###### Indicator exit duration — `0.34`

```sh
defaults write com.omeriadon.DockReflections indicatorExitDuration -float 0.34
```

### Restart Dock

```sh
killall Dock
```
