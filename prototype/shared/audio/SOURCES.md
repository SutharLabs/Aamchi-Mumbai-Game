# Shared audio sources

## Parcel pickup

`parcel-pickup.wav` adapts the collection page-turn sound from the original *Duelyst* by Counterplay Games. OpenDuelyst preserves the original game’s content from before the 2020 shutdown, and the released game registers this sound as `sfx_collection_next`. [Preserved game release](https://github.com/open-duelyst/duelyst/blob/df697549cad25dae6f7a2a863989e2e380841a5b/README.md) · [Original sound registration](https://github.com/open-duelyst/duelyst/blob/df697549cad25dae6f7a2a863989e2e380841a5b/app/data/resources.js#L3929)

The release places the file under CC0 1.0 Universal, which permits commercial reuse, adaptation and redistribution without an attribution requirement. Credit for project notices is **Page-turn sound adapted from Duelyst by Counterplay Games, released through OpenDuelyst under CC0 1.0 Universal**. [Counterplay release announcement](https://www.youtube.com/watch?v=h3Cuz6d_7x0) · [License in the source revision](https://github.com/open-duelyst/duelyst/blob/df697549cad25dae6f7a2a863989e2e380841a5b/LICENSE)

| File | SHA-256 |
| --- | --- |
| [Upstream `app/resources/sfx/sfx_ui_nextpage.m4a`](https://github.com/open-duelyst/duelyst/blob/df697549cad25dae6f7a2a863989e2e380841a5b/app/resources/sfx/sfx_ui_nextpage.m4a) | `9a38f9af3e3635f938ad89ea306b0a09d782eec8d8202c099c3972fc5136aa5c` |
| `parcel-pickup.wav` | `83b207e993491b47fdaf8833fd6bb0a0be7abb827a1eb3268e0d101db9457e5b` |

The downloaded file matched Git blob `d326c2a2bdf2609fcffdf256e0396ae5f51a38ff` at the pinned revision. The adapted cue keeps the short rustle, rolls off the bass and treble, trims the tail, and attenuates the source by 10 dB. The shared file is 0.360 seconds of signed 16-bit PCM at 24 kHz in mono. Use it for a successful parcel pickup.

Conversion used FFmpeg 9.0.2 with the following arguments.

```text
ffmpeg -i sfx_ui_nextpage.m4a -map 0:a:0 -map_metadata -1 -af "highpass=f=120,lowpass=f=7500,afade=t=in:st=0:d=0.010,afade=t=out:st=0.26:d=0.10,volume=-10dB" -t 0.36 -ac 1 -ar 24000 -c:a pcm_s16le -fflags +bitexact -flags:a +bitexact parcel-pickup.wav
```

## Omkar’s sandal footsteps

Both engines use three isolated walking contacts from NaoRenma’s **steps (2).wav** and three running contacts from sturmankin’s **concrete_04c_sandals_run.wav**. The authors identify the recordings as sandals on a hard floor and sandals running on concrete, respectively. Both source pages designate their recordings CC0. [Walking recording](https://freesound.org/people/NaoRenma/sounds/188849/) · [Running recording](https://freesound.org/people/sturmankin/sounds/272289/)

| Shared stems | Public preview SHA-256 | Trim starts in order |
| --- | --- | --- |
| `sandal-walk-1.wav` through `sandal-walk-3.wav` | `f92e31557f75dc5400b0ce9b6023353979a741166f3d6833ab06ac42ce80e2ab` | 3.310750 s, 3.875583 s, 5.477292 s |
| `sandal-run-1.wav` through `sandal-run-3.wav` | `aa5539e86bec80a009e28ad2debde5098e4dc3bf1eb4230954b1c3811bb148be` | 9.847250 s, 15.390625 s, 17.910042 s |

The Freesound high-quality previews were decoded with FFmpeg and trimmed to 185 ms at 24 kHz mono, signed 16-bit PCM. A 65–7,500 Hz band-pass reduces handling noise and room tone. Short edge fades and a peak limit retain the sandal strikes. With the game’s running gain, the digital clip RMS is roughly 10 dB below the prior Unreal synthetic running samples before distance attenuation. Runtime alternates foot placement, varies samples within each gait and times running hits to the first supported frames in the current mocap clip. [Captured foot contact check](../../tests/run_foot_contact_smoke.gd)
