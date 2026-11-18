# Music prompts (story 055)

The music made in code can't sound like a produced track. These prompts are for free AI music
tools, so the score can sound the way you want: lo-fi like Mac DeMarco, The Long Faces and Lady
Radiator while exploring, and dark rage or trap like Yeat and SDEkid in fights and boss battles.

## Which tool

| Tool | Free tier (check, it changes) | Notes |
| --- | --- | --- |
| **Suno** (suno.com) | About 10 songs a day | Best results. Use "Custom" mode, paste the style line into "Style of Music", tick **Instrumental**. |
| **Udio** (udio.com) | Some songs a day | Good for lo-fi texture. Turn on **Instrumental**. |

The tools refuse artist names, so the prompts describe the sound instead of naming Yeat or Mac
DeMarco. Generate 2 or 3 versions of each and keep the one you like.

## How to deliver

- Make each track at least 2 minutes long. Pick one where the beat stays steady (no long silent
  intro).
- Download it (MP3 is fine, WAV is better) and name it exactly as in the tables below, e.g.
  `zone1_explore.mp3`.
- Put the files in `docs/design/music/`.

What I do with them:
1. Find a clean section, cut it to whole bars at its tempo so it loops without a seam.
2. Match each zone's explore and fight tracks in tempo and length so the game can switch between
   them on the beat.
3. Keep my ambience and sound effects, and keep each Vessel's leitmotif quietly on top if it fits.
   I drop it if it clashes.

The exploring tracks and the fight tracks of one zone **must share the key and the tempo**. The
fight tempo is double the explore tempo (trap's half-time feel), so they lock together.

## The tracks

### Exploring (lo-fi)

Shared style line, pasted first, then add the zone line after it:

> lo-fi indie, bedroom pop, melancholic, hazy, warbly tape wow and flutter, chorus-drenched clean
> electric guitar, detuned vintage electric piano, soft swung drum machine, mellow round bass,
> vinyl crackle, dreamy, slow, instrumental, dark gothic undertone, loopable

| File | Zone | Add to the style line | Key | BPM |
| --- | --- | --- | --- | --- |
| `zone1_explore` | The Whispering Cavern | cold cave reverb, distant church bell, dripping water, blue and lonely | A minor | 70 |
| `zone2_explore` | The Luminous Mycelium Forest | glassy chimes, soft glowing pads, gentle wonder with sadness under it | D minor | 84 |
| `zone3_explore` | The Sunken Palace | underwater muffled tone, faded waltz feel, tarnished elegance, harp-like plucks | E minor | 72 |
| `zone4_explore` | The Sealed Rift | heavy and slow, low drone, embers crackling, dread, sparse | D minor | 66 |
| `zone4_shore_explore` | The Starless Shore | vast empty space, waves, very sparse, almost ambient, hopeless calm | E minor | 60 |
| `altar` | Soul Altar (rest and save) | no drums, warm, safe, candlelit, hymn-like chords on electric piano | A minor | 60 |
| `title` | Title screen | the main theme: a sad, memorable melody on electric piano and chorused guitar, slow build | A minor | 70 |

### Fighting (dark rage and trap)

Shared style line:

> dark rage trap, distorted 808 bass with slides, rolling triplet hi-hats, hard claps, aggressive
> bright detuned bell synth lead, menacing, hypnotic, gothic choir pad underneath, cathedral organ
> stabs, instrumental, no vocals, loopable, energetic

| File | Zone | Add to the style line | Key | BPM |
| --- | --- | --- | --- | --- |
| `zone1_fight` | The Whispering Cavern | church bell hits, cold and echoing | A minor | 140 |
| `zone2_fight` | The Luminous Mycelium Forest | glassy plucked arps, spore-like glitches | D minor | 168 |
| `zone3_fight` | The Sunken Palace | harp and strings sampled and chopped, drowned and regal | E minor | 144 |
| `zone4_fight` | The Sealed Rift | extremely distorted 808, industrial clanks, fire | D minor | 132 |
| `zone4_shore_fight` | The Starless Shore | huge reverb, slow and crushing, deep sub | E minor | 120 |

### Bosses (the hardest tracks)

Shared style line:

> epic dark rage trap boss battle, massive distorted 808s, rapid hi-hat rolls, gothic choir,
> cathedral organ, church bells, aggressive bell synth lead, relentless build, menacing,
> instrumental, no vocals, loopable

| File | Boss | Add to the style line | Key | BPM |
| --- | --- | --- | --- | --- |
| `boss_sovereign` | The Weeping Sovereign | tragic and regal, weeping strings, a queen's lament turned violent | E minor | 152 |
| `boss_guardian` | The Guardian Below | heavy stone, slow crushing drums, industrial, colossal | D minor | 130 |
| `boss_leviathan` | The Abyssal Leviathan | deep sea dread, sonar pings, gigantic sub bass, chaotic | E minor | 144 |
| `finale` | End of Chapter I | slow, emotional, the title melody on choir and electric piano, hopeful but broken | A minor | 70 |

Each boss track plays through all three phases. If you want them to change by phase, make two
versions of a boss, the normal one and one with "climax, maximum intensity, faster rolls" added,
named `boss_sovereign_final` and so on. The final version plays in the last phase.

## A free option without AI

Royalty-free music sites, such as Pixabay Music, have lo-fi and dark trap instrumentals that are
free to use in games. Search "dark lofi" and "dark trap beat". Name the files the same way and I
wire them in the same way.
