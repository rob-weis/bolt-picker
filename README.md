# Bolt Picker

A small, fast macOS menu bar color picker. Click the eyedropper, then click any
pixel on screen. Its hex is copied to the clipboard and saved in a 30-color history
that also shows each color's RGB and CMYK values.

## Use

- **Menu bar eyedropper** → opens the panel.
- **Pick** (or Return) → a magnifier follows the cursor and shows the live hex.
  Click to copy, or press **Esc** / right-click to cancel.
- **History:** click a row to copy its hex. Right-click a row for Copy Hex, Copy RGB,
  Copy CMYK or Remove. **Clear** empties the list.
- **Settings (gear):** include `#`, uppercase letters, launch at login.

## Build and install

Requires Xcode 16+ and XcodeGen (`brew install xcodegen`).

```sh
make test      # generate the Xcode project and run unit tests
make install   # build Release, copy to /Applications, launch
```

`BoltPicker.xcodeproj` is generated from `project.yml`. Edit `project.yml`, not the project.

## Permissions and security

- **Screen Recording** is the only permission. macOS asks the first time you pick.
  Turn on Bolt Picker in System Settings ▸ Privacy & Security ▸
  Screen & System Audio Recording, then reopen the app. macOS 15 occasionally asks
  you to confirm this again. That's a system behavior for all screen-capture apps.
- The screen is captured **only while you're picking**. Capture stops the moment
  you click or cancel. Frames stay in memory and are never saved. The only thing
  stored is the hex of the colors you pick, in the app's sandbox preferences.
- Sandboxed with **no other entitlements** (no network, no file access). Hardened
  runtime is on. There are no third-party dependencies.

## Signing

See `Config/Signing.xcconfig`. It's ad-hoc signed until your Apple
developer account is added to Xcode. With ad-hoc signing, macOS may ask for Screen
Recording permission again after each rebuild.

## Accuracy

Colors are captured in sRGB, the color space used by CSS, Figma's default and most
web tools. Open `Tools/swatches.html` in a browser and pick each swatch to check.
CMYK uses the standard screen conversion formula, not a print ICC profile.
