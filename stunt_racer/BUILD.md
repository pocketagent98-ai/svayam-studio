# Building and publishing the Android APK

## What you have

`StuntRacer.apk` — a **signed, installable** Android build of the game.

- Package: `com.svayam.stuntracer`
- Architecture: arm64-v8a (every modern Android phone)
- Size: ~28 MB
- Signed with the standard **Android debug key** (scheme v2 + v3, verified)

## Install it and play

**On the phone (simplest):** copy the APK to the phone, tap it, and allow
"install from unknown sources" when asked.

**From a computer with the phone plugged in:**

```
adb install -r StuntRacer.apk
```

## Rebuilding it yourself

You need three things:

1. **Godot 4.7.2** (standard Linux build)
2. **Godot export templates** for 4.7.2, unpacked into
   `~/.local/share/godot/export_templates/4.7.2.stable/`
3. **Android SDK** (build-tools + platform-tools + platform 34) and a **JDK 17**

Then, in the Godot editor set:

- `Editor Settings -> Export -> Android -> Android SDK Path` -> your SDK folder
- `Editor Settings -> Export -> Android -> Java SDK Path` -> your JDK folder

and export:

```
godot --headless --path stunt_racer --export-debug "Android" StuntRacer.apk
```

The `export_presets.cfg` in this folder is already configured. Note that
**ETC2/ASTC** texture import must be on (`rendering/textures/vram_compression/import_etc2_astc=true`),
which it is in `project.godot` — Godot refuses an Android export without it.

## Publishing to Google Play

Two things are different for a real store release, and both matter:

**1. Your own release key.** A debug-signed APK is fine for testing and
sideloading, but Google Play will not accept it. Generate your *upload key* once
and keep it safe — if you lose it you cannot update the app:

```
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Store that file and its password somewhere you will not lose. In Godot, set
`Editor Settings -> Export -> Android -> Release Keystore` to it.

**2. An Android App Bundle (.aab), not an APK.** Google Play requires AAB for
new apps. Godot produces an AAB only when the **Gradle build** is enabled:

- Export -> Android -> enable `Gradle Build`
- Install the Android build template (Project -> Install Android Build Template)
- Then `Export -> Android -> Export Format -> Android App Bundle`

You then upload the `.aab` in the Play Console, fill in the store listing, and
submit for review.

## Honest note on scope

This APK is the **vertical slice** from your plan (one full cycle of the core
loop). It is a real, playable game — but it is not yet the finished product your
PRD describes. Ramps, loops, fans and pendulums, AI opponents, the 30-car
garage, boss racers, Unity Ads and the mobile optimisations are still to come.
