# Story 007: Combat core — hitboxes, damage, posture, telegraphs, parry, riposte

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Core · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Core combat systems" (Posture, Riposte, parry, player hidden posture,
Telegraphs with colour + shape + sound, elements/status), "Damage formula"; bible section 1 Combat
Telegraphing Standard. **Decision**: D-003.

## Acceptance Criteria

- [ ] `DamagePacket` (RefCounted): attacker, atk, motion_value, element, posture_damage, kind (`parryable` / `unblockable` / `magic`), knockback, source position.
- [ ] `Hurtbox` (Area3D) routes to `Health` and `Posture` components on the owner; `Hitbox` (Area3D) activates for a window and hits each hurtbox once per swing.
- [ ] `Posture`: fills from hits (times the attacker posture multiplier) and parries; full = `staggered` 2.5 s with a Riposte prompt; riposte deals x2; drains 10/s after 2 s unhit. Player posture 100, hidden; full = 1 s guard break.
- [ ] `Telegraph` node: plays the standard cue 0.6-1.2 s before a hit: gold ring / crimson X / violet diamond sprite above the attacker, mesh flash colour, and the matching SFX (`chime`, `boom`, `harmonic`); the specific enemy tell plays alongside.
- [ ] Block (hold `ability_1` on Caelan): 100 % frontal, 10 stamina per hit, fills player posture on heavy hits. Parry: a block that starts within 0.18 s before a `parryable` hit is a perfect parry: no damage, +15 stamina, 35 posture to the attacker, `parried` signal (Counterstrike hook). `unblockable` hits ignore block; `magic` is blocked by Aether Shield only.
- [ ] Perfect dodge: an i-frame dodge that starts within 0.1 s of a hit's impact emits `perfect_dodge` (Soul Gauge +10).
- [ ] Hitstop 0.05 s on hit, 0.12 s on parry; damage numbers behind a debug flag.
- [ ] `StatusEffects` component with build-up meters for Frost, Venom, Aether, Ember, Stagger, per the elements table (M1 sources are Physical only; the framework is complete).
- [ ] Unit tests: posture fill/stagger/drain, parry window edges (0.17 s pass, 0.19 s fail), block stamina, hurtbox once-per-swing, status build-up thresholds.

## Files

- `src/combat/damage_packet.gd`, `hitbox.gd`, `hurtbox.gd`, `health.gd`, `posture.gd`, `status_effects.gd`, `telegraph.gd`, `guard.gd`, `hitstop.gd`
- `src/vfx/telegraph_icons.gd` (ring, X and diamond drawn procedurally at boot; no emoji, no font glyphs)
- `tests/unit/combat/posture_test.gd`, `parry_window_test.gd`, `hitbox_test.gd`, `status_effects_test.gd`

## Dependencies

- Depends on: 004, 006 · Unlocks: 008, 009, 010
