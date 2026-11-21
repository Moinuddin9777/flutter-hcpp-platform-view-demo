# HCPP Demo: Two Rendering Worlds, One Screen

**A FlutterCon talk demo showing why Flutter needed Hybrid Composition++**

Clone it, run it on an Android device, and immediately *see* the difference between
classic Hybrid Composition (HC) and the new Hybrid Composition++ (HCPP).

---

## The Two Rendering Worlds

Flutter and native Android platform views (like WebView) live in separate rendering pipelines.
Compositing them on a single screen has always been challenging:

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER WORLD                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Skia/Impeller → Flutter Compositor → SurfaceTexture     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   SurfaceFlinger                         │◄──┼── Android composites
│  └──────────────────────────────────────────────────────────┘   │   the final frame
│                              ▲                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Native View → TextureLayer OR SurfaceControl            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                        NATIVE WORLD                             │
└─────────────────────────────────────────────────────────────────┘
```

**Classic Hybrid Composition (HC):** Copies native view pixels through a texture layer.
Works everywhere, but adds latency and can cause synchronization jank when both worlds
animate simultaneously.

**Hybrid Composition++ (HCPP):** Uses Android 14+ `SurfaceControl` APIs to let both
Flutter and native views composite directly in SurfaceFlinger—same frame, same vsync,
no texture copies in the middle.

---

## What You'll See

A food-ordering app screen with:

| Element | Rendered By | Purpose |
|---------|-------------|---------|
| Restaurant header | Flutter | Static Flutter UI |
| Scrollable menu | **Native WebView** | Platform view content |
| Floating cart button | Flutter | Overlaps the WebView |
| Bouncing animated orb | Flutter | Continuous animation to spot jank |
| Cart total bar | Flutter | Interactive Flutter UI |

**Toggle the "layers" button** to tint and label which pixels are Flutter (green) vs Native (red).

**Compare HC vs HCPP:** Run in both modes and scroll the menu while watching the bouncing orb.
On supported devices, HCPP should show smoother animation during simultaneous Flutter + WebView
activity.

---

## Requirements

| Requirement | Why |
|-------------|-----|
| Flutter 3.29+ stable | HCPP support in stable channel |
| Android API 34+ device | `SurfaceControl` APIs for HCPP |
| Vulkan-capable GPU | Impeller backend requirement |
| Physical device recommended | Emulators may not represent HCPP accurately |

---

## Quick Start (3 Commands)

```bash
# 1. Clone and enter
git clone <this-repo> && cd hcpp-demo

# 2. Get dependencies
flutter pub get

# 3. Run with HCPP enabled
make run-hcpp
```

---

## Running HC vs HCPP

The app and workload stay identical—only the composition configuration changes.

```bash
# HCPP mode (Hybrid Composition++)
make run-hcpp

# Classic HC mode (Hybrid Composition)
make run-hc

# Profile mode (for DevTools analysis)
make run-hcpp-profile
make run-hc-profile
```

Or manually with flutter run:

```bash
# HCPP enabled
flutter run -PenableHcpp=true

# HCPP disabled (classic HC)
flutter run -PenableHcpp=false
```

---

## Confirming HCPP is Active

Check logcat for the magic line:

```bash
adb logcat | grep -i "HCPP"
```

**When HCPP is active:**
```
Using HCPP platform view rendering strategy
```

**When classic HC is active:**
```
Using Hybrid Composition platform view rendering strategy
```

---

## What to Look For

### In the App
1. **Scroll the WebView menu** while watching the bouncing orb
2. **Tap menu items** to add to cart (tests JS → Flutter communication)
3. **Toggle region labels** to see Flutter vs Native boundaries
4. **Compare smoothness** between HC and HCPP modes

### In Flutter DevTools
- Open **Performance** tab
- Look at **Frame timing** during simultaneous scroll + animation
- Check for **jank frames** (frames > 16ms)

### In Perfetto/Systrace
- Look at **SurfaceFlinger** traces
- Compare **FrameTimeline** between modes
- Observe **platform thread** vs **raster thread** activity

---

## How HCPP is Configured

The toggle happens via manifest metadata, controlled by a Gradle property:

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableHcpp"
    android:value="${enableHcpp}" />
<meta-data
    android:name="io.flutter.embedding.android.ImpellerBackend"
    android:value="vulkan" />
```

**`android/app/build.gradle.kts`:**
```kotlin
val enableHcpp: String = project.findProperty("enableHcpp")?.toString() ?: "true"
// ...
manifestPlaceholders["enableHcpp"] = enableHcpp
```

---

## Project Structure

```
hcpp_demo/
├── lib/
│   └── main.dart           # Flutter UI with WebView + animations
├── assets/
│   └── menu.html           # Local HTML menu (no network required)
├── android/
│   └── app/
│       └── src/main/
│           └── AndroidManifest.xml  # HCPP configuration
├── Makefile                # Convenience targets for HC/HCPP modes
├── LICENSE                 # MIT
└── README.md               # You are here
```

---

## Caveats

- **HCPP is not a silver bullet.** Performance depends on device, driver, and workload.
- **Emulators may not reflect real behavior.** Test on physical API 34+ devices.
- **HCPP requires Impeller with Vulkan backend.** Devices without Vulkan fall back to HC.
- **This demo does not fabricate performance numbers.** Run it yourself to see.

---

## Credits

- **Reference implementation:** [amaan-0331/hcpp-onendframe-crash-repro](https://github.com/amaan-0331/hcpp-onendframe-crash-repro) — studied for HCPP configuration approach
- **Flutter HCPP docs:** [Platform Views on Android](https://docs.flutter.dev/platform-integration/android/platform-views)

---

## License

MIT — see [LICENSE](LICENSE)
