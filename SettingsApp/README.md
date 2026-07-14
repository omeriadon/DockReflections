# Dock Reflections Settings

Open `DockReflectionsSettings.xcodeproj`, select the `DockReflectionsSettings` scheme, and run the macOS app.

The app is intentionally not sandboxed. It writes `com.omeriadon.DockReflections` preferences and restarts Dock through `/usr/bin/killall`.

Regenerate the project after changing `project.yml`:

```sh
xcodegen generate
```
