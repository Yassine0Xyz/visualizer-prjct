# Audio Visualizer Lab

A standalone, experimental Flutter application for researching and comparing
high-quality, genuinely audio-reactive visualizers. Independent of any other
project — nothing here connects to or modifies external repositories.

Import a local audio file, play it, and explore a collection of visualizers
driven by a real FFT analysis pipeline (no fake/random animation).

---

## Features

- Import local audio (`file_picker`), play / pause / resume / stop / seek
  (`just_audio`).
- Full offline analysis pipeline: FFmpeg decode → mono 22050 Hz PCM →
  overlapping Hann windows → radix-2 FFT → 48 log-spaced bands → adaptive
  per-band peak normalization → bass / mid / high / energy aggregates.
- 9 distinct visualizer styles, each with its own identity and behavior.
- Live smoothing engine (fast attack, slow release) so quiet sections stay
  alive and visuals never snap.
- Customization: sensitivity, smoothness, intensity, glow (on/off + radius),
  6 color themes with optional energy-driven dynamic hue.
- Fullscreen immersive mode, premium dark UI.

---

## Project structure

```
audio_visualizer_lab/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── lib/
    ├── main.dart
    ├── app.dart
    ├── core/
    │   ├── analysis/
    │   │   ├── audio_frame.dart        # Immutable analysis snapshot (data model)
    │   │   ├── fft.dart                  # Pure-Dart iterative radix-2 FFT
    │   │   ├── spectrum_analyzer.dart  # Bands, normalization, aggregates
    │   │   └── analysis_backend.dart   # FFmpeg decode + isolate execution
    │   ├── audio/
    │   │   ├── audio_engine.dart       # Thin just_audio wrapper
    │   │   └── audio_track.dart        # Track model
    │   └── theme/
    │       └── app_theme.dart          # Dark theme + glass helpers
    └── features/
        ├── player/
        │   ├── player_controller.dart  # Orchestrates engine + analysis + data
        │   └── screens/
        │       ├── home_screen.dart
        │       ├── visualizer_screen.dart
        │       ├── fullscreen_visualizer_screen.dart
        │       └── settings_panel.dart
        └── visualizers/
            ├── visualizer_config.dart  # User-tunable settings (ChangeNotifier)
            ├── visualizer_data.dart    # Smoothed live state (ChangeNotifier)
            ├── visualizer_theme.dart   # Color presets
            ├── visualizer_style.dart   # Style enum + metadata
            ├── visualizer_view.dart    # Ticker-driven renderer + painter factory
            ├── base/
            │   └── visualizer_painter.dart
            └── styles/
                ├── bars_painter.dart
                ├── wave_painter.dart
                ├── columns_painter.dart
                ├── mirror_painter.dart
                ├── circular_painter.dart
                ├── radial_painter.dart
                ├── fluid_painter.dart
                ├── particles_painter.dart
                └── geometric_painter.dart
```

---

## Implemented visualizer styles

| Style      | Behavior |
|------------|----------|
| **Bars**   | Classic bottom-anchored rounded spectrum bars with gradient + glow. |
| **Wave**   | Catmull-Rom smoothed spectrum line with gradient fill and a faint mirrored echo. |
| **Columns**| Equalizer wall: 24×14 grid of glowing blocks, column height per band. |
| **Mirror** | Symmetric bars expanding above/below a luminous center axis. |
| **Circular**| Radial bars around a ring, rotating with the beat; pulsing bass core. |
| **Radial** | Filled polar spectrum blob with an echoing inner contour. |
| **Fluid**  | Three layered liquid waves driven by bass/mid/high; drift follows energy. |
| **Particles**| Orbiting particle field pushed outward by per-band values. |
| **Geometry** | Rotating low-poly rings that breathe with bass/mid/high. |

All styles consume the same `AudioFrame` stream — switching styles never
changes the analysis.

---

## Audio analysis architecture

```
audio file
   │  ffmpeg_kit_flutter_audio  (-ac 1 -ar 22050 -f s16le)
   ▼
mono PCM (Float32List)  ──compute()──►  isolate
   │                                        │
   ▼                                        ▼
SpectrumAnalyzer.analyzePcm()        FFT (2048, radix-2, precomputed tables)
   │                                        │
   ▼                                        ▼
48 log-spaced bands ◄── Hann window, per-band power
   │
   ▼
adaptive per-band peak normalization (fast attack / slow release)
   │
   ▼
AudioFrame { bands[48], bass, mid, high, energy, timeMs }   (~46 fps)
```

At runtime, `PlayerController` interpolates between adjacent frames at the
current playback position, applies the user sensitivity gain with a tanh
soft-clip, and pushes targets into `VisualizerData`, which applies
asymmetric exponential smoothing (fast attack, slow release) before painters
read it. Rendering is driven by a `Ticker`, so visuals advance at the display
refresh rate (60/90/120 Hz).

---

## Dependencies & licenses

| Package | Purpose | License |
|---|---|---|
| `just_audio` | Playback | MIT |
| `ffmpeg_kit_flutter_audio` | PCM decoding for analysis (LGPL build — no GPL codecs bundled) | LGPL-3.0 |
| `file_picker` | Local audio import | MIT |
| `path_provider` | Temp dir for decoded PCM | BSD-3-Clause |
| `path` | Path utilities | BSD-3-Clause |
| `cupertino_icons` | Icons | MIT |
| `flutter_lints` (dev) | Lints | BSD-3-Clause |

Flutter SDK: Dart `>=3.4.0 <4.0.0`.

---

## Known limitations

- Android platform scaffolding is generated by the GitHub Actions workflow
  before the CI build. To build locally, generate the Android platform with
  `flutter create --platforms=android --org com.yassine .` first.
- Analysis is offline (whole file decoded before playback starts). Long
  tracks take a few seconds to load and use temporary disk space.
- No microphone / streaming input — local files only.
- FFT runs in pure Dart inside an isolate; on very low-end devices the
  one-time analysis step may take a few seconds for long tracks. Runtime
  rendering itself is lightweight (CustomPainter only).
- `ffmpeg_kit` is archived upstream; the pinned `ffmpeg_kit_flutter_audio`
  4.6.x still works on current Flutter stable, but plan a migration path
  (e.g. `media_kit` or platform channels) for future-proofing.

---

## Running locally

```bash
flutter create --platforms=android --org com.yassine .
flutter pub get
flutter analyze
flutter test
flutter run            # on a connected device/emulator
# or
flutter build apk      # Android
```

## Continuous integration

The **Flutter Android profile APK** workflow runs on pushes and pull requests
to `main`, and can also be started manually from the Actions tab. It generates
the Android platform files, runs `flutter analyze` and `flutter test`, then
builds a profile APK with `flutter build apk --profile`. Download the resulting
`audio-visualizer-profile-apk-*` artifact from the workflow run; artifacts are
retained for 14 days.

On first run: **Import audio** → pick a local track → press play.

---

## Extracting visualizers into YAZEN Player

The visualizer layer is deliberately decoupled. To reuse it:

1. Copy `lib/features/visualizers/` (plus `lib/core/analysis/` if you want the
   same offline pipeline) into your app.
2. Feed `VisualizerData.update(...)` from your own analysis source — the
   painters only need `VisualizerData`, `VisualizerConfig` and
   `VisualizerThemeData`; they never touch playback code.
3. If your player already has a live PCM stream, replace
   `AnalysisBackend` with a real-time tap and keep `SpectrumAnalyzer` as-is.
4. If you use a different player plugin, re-implement `AudioEngine` only —
   `PlayerController` is the single place that knows about `just_audio`.
5. Keep `VisualizerView` as the widget entry point; it owns the render loop.

License note: `ffmpeg_kit_flutter_audio` (LGPL) is used here only for the
analysis side. If you ship visualizers in a proprietary player, either keep
FFmpeg usage optional or replace the decode step; the visualizers themselves
are pure Flutter/Dart with no copyleft dependency.
