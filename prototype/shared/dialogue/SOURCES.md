# Ranwar dialogue

The project wrote the scripts and English subtitles in [lines.json](lines.json). The Hindi audio uses the stock `hf_alpha`, `hf_beta`, `hm_omega` and `hm_psi` Kokoro presets. The project synthesized the clips locally on 23 November 2026 with no reference performance or personal recordings. The model and its presets are under Apache 2.0 in the pinned [Kokoro model card](https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/README.md) and [voice list](https://huggingface.co/hexgrad/Kokoro-82M/blob/f3ff3571791e39611d31c381e3a41a3af07b4987/VOICES.md).

Each WAV is 24 kHz mono signed 16-bit PCM. The clips use their catalogue's per-line preset and speed, with silence trimmed to leave a short lead and tail. Peaks were limited to 70% of full scale and RMS was capped at −20.5 dBFS. The subtitle duration comes from the resulting WAV. Godot imports the source files from this folder. The Unreal build copies the same bytes into `Audio/Ranwar/Dialogue`. The builds ship neither inference code nor model weights.

English subtitles are translations of the Hindi script. The Hindi voice tracks are first-pass synthetic performances. Local review should listen for the pronunciation of street names and delivery terms before these clips are accepted for a public build.
