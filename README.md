# Dock Reflections

> [!WARNING]
> You must disable SIP and Library Vaildation to run this, and you need Ammonia installed. Do not attempt running this unless you know what you are doing and the risks involved.

An experimental Ammonia tweak for macOS that adds icon reflections beneath the Dock and replaces the standard running-app indicators with configurable glowing indicators.

The tweak currently targets Apple Silicon and relies on private Dock implementation details. System updates can change those details.

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

The native macOS settings app in [`SettingsApp`](SettingsApp) exposes every supported option and includes a Restart Dock button. Open `SettingsApp/DockReflectionsSettings.xcodeproj` in Xcode and run the `DockReflectionsSettings` scheme.

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
