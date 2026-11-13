# Evidence — Story 013: Debug HUD, playtest bridge, sandbox APK

Run result: VERIFIED on Windows (live game driven through the bridge) and on Android 16 (emulator,
arm64 APK through ARM translation, driven through the bridge over `adb forward`).

## Scripted playtest — 44 / 44 checks

`bash tools/python.sh tools/playtest/drive.py` launches the game windowed with `--no-waves`, drives
it through the bridge and compares against `data/balance` read live. Full output:
`playtest-output.txt`. Highlights:

| Area | Observed |
| --- | --- |
| Soul HP | 460 = 300 + Caelan 120 + Nyra 40 |
| Movement | 5.83 m in 1 s at 6 m/s; jump apex 2.2 m (integration test); air-dash 4.00 m |
| Dodge | i-frames present; 20 stamina (data 20) |
| Crawler | dies to Caelan in 3 presses; crimson boom cue; lunge goes through Royal Guard |
| Block / parry | blocked thrust: 0 HP lost, 10 stamina; perfect parry: Warden guard opens, +10 gauge |
| Warden shield | front hit 6.7, backstab from behind 60.5 |
| Swap | Nyra in, 1.5 s cooldown, Severing Arrival deals 90; second swap refused on cooldown |
| Nyra | Shadowstep 5.83 m; Vanishing Act hides; Phantom Blades hit at range |
| Ultimates | Final Stand costs 2 bars, kills 3 Crawlers; Dance of Shadows 900 → 496 on a Warden |
| Sync Guards | inactive Nyra swaps in and evades an unblockable lunge; Caelan intercepts a lethal parryable blow (1 bar) |
| Watcher | charges, sweeps, beam damages the player |
| Music | elite layer on a 4-bar boundary (off 0.010 s); clock drift vs playback 0.046 s |

## Screenshots

`01` Crawler crimson X + red flash + green spine sacs · `02` Warden guard broken after a parry ·
`03` Nyra after Severing Arrival · `04` Final Stand · `05` Dance of Shadows · `06` Watcher violet
diamond + aim line · `07` Watcher beam · `08` **Android 16 emulator**: Warden gold ring + gold flash,
Watcher beam, HUD and touch arc at 2400x1080.

## Android

```
I godot: Vulkan 1.2.0 - Forward Mobile - Using Device #0: ... SwiftShader Device
I godot: SOULVESSELS_BOOT_OK version=0.1.0 renderer=mobile physics=Jolt Physics
```

- APK: `builds/android/soulvessels-debug.apk`, 30 MB, signed (debug key), `lib/arm64-v8a` only,
  `data/**/*.json` packed, tests and docs excluded.
- First Android boot found a real bug: the bridge could not open its socket (Android needs the
  INTERNET permission even for localhost). Fixed in the debug preset (`permissions/internet=true`,
  decision D-015); the second boot was clean and the bridge answered over `adb forward`.
- Emulator FPS is 1–2 (software Vulkan + ARM translation): **not** a performance number.
  Memory PSS ~490 MB.

## Not verified

- 60 FPS and < 1.8 GB on a real mid-range phone (no device attached).
- Touch feel on glass (all touch checks used injected events).
- Bluetooth gamepad on Android (desktop pad events only).
