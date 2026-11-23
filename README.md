# Audio Visualizer Lab V2

A standalone Flutter application for researching and comparing
high-quality, audio-reactive visualizers. Version 2 includes 18 implemented
visualizer styles and an updated analysis pipeline.

## Features V2

- 18 unique visualizer styles (9 original + 9 new premium styles)
- Real FFT analysis pipeline with 64 frequency bands
- Enhanced audio reactivity: bass, mid, high, energy, and raw energy values
- Premium dark UI with glassmorphism design
- Full customization: sensitivity, smoothness, intensity, bass boost, glow, particles, mirror
- 8 color themes with dynamic hue shifting
- Fullscreen immersive mode
- Animated rendering with interpolated spectrum updates

## 18 Visualizer Styles

### Original 9:
1. **Bars** - Classic spectrum bars
2. **Wave** - Smooth interpolated wave
3. **Columns** - Equalizer wall
4. **Mirror** - Symmetric bars
5. **Circular** - Radial bars
6. **Radial** - Polar spectrum blob
7. **Fluid** - Layered liquid waves
8. **Particles** - Orbiting particle field
9. **Geometry** - Rotating low-poly rings

### New Premium 9:
10. **Neon Bars** - Neon light bars with trails and tips
11. **Bass Circle** - Pulsing circles with bass spikes
12. **Frequency Rings** - Concentric rings with arc segments
13. **Energy Wave** - Multi-layer energy-driven waves
14. **Particle Explosion** - Explosive outward particles
15. **Pulsing Center** - Center pulse with radial lines
16. **Spectrum Rings** - Rotating spectrum as rings
17. **Fluid Bass** - Liquid blobs responding to bass
18. **Circular Wave** - Circular wave with spokes

## Architecture

```
audio file
   │  ffmpeg_kit_flutter_new_audio
   ▼
mono PCM → isolate → FFT (2048, radix-2) → 64 log-spaced bands
   │
   ▼
AudioFrame { bands[64], bass, mid, high, energy, bassEnergy, midEnergy, highEnergy }
   │
   ▼
PlayerController → interpolation → VisualizerData → CustomPainter @ 60fps+
```

## Dependencies

| Package | Purpose | License |
|---|---|---|
| `just_audio` | Playback | MIT |
| `ffmpeg_kit_flutter_new_audio` | PCM decoding | LGPL-3.0 |
| `file_picker` | Audio import | MIT |
| `path_provider` | Temp storage | BSD-3-Clause |
| `path` | Path utilities | BSD-3-Clause |

## Running

```bash
flutter pub get
flutter run
```

The Android build uses API 24 or newer and Flutter 3.41 or newer.

## Integration into YAZEN Player

Copy `lib/features/visualizers/` into your app. Painters only need
`VisualizerData`, `VisualizerConfig`, and `VisualizerThemeData`.
