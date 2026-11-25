# Ranwar shop model sources

## Rooftop props

The district uses two CC0 models, acquired on 24 November 2026. The portable GLBs bundle PNG maps and regular mesh buffers after a Blender 5.3 re-export. Pivots and metre scale were retained. These props are placed visually on existing roofs. [Placement](../ranwar_roof_props.gd)

| Model | Source SHA-256 | Adapted GLB SHA-256 |
| --- | --- | --- |
| Rooftop Water Tank on Frame, 368 triangles. [3DAssets.dev, CC0](https://3dassets.dev/assets/indian-bazaar-street-and-temple-rooftop-water-tank-c4ec1b54) | `9e17191afd557e060b36230742088a0393ea93945e9179720af5abba373cd1e4` | `e6ba2b188bfa33828dab05f6d9d14b77be945bcb980466de4e816f86fe595fe6` |
| Rooftop Condenser Pair, 316 triangles. [Tevy, CC0](https://tevy.dev/models/rooftop-condenser-pair) | `553c1b86dfcede9d763dbf9fcf23cfb7a166bab19e992430209b9489923c2cbc` | `cbc60e0c297a26000741c380fee3eb0bd3ee8e803af0ebc54d51c5bb5f810ea4` |

**Indian street shop** by **nayan pachori**, acquired **23 November 2026** from Sketchfab. The downloaded GLB remains unchanged in the repository. The deployment scales and centres the scene, faces the shutter toward Hill Road and adds a simple collision box beside the original fictional grocery storefront. Godot imports the three embedded maps using Basis Universal. [Original model](https://sketchfab.com/3d-models/indian-street-shop-a7476a895cb841709ccbd5d9d8b96f36) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

The archive is **2,090,820 bytes**. Its SHA-256 is `2ddd0ed97d8ffcfa3babaed9e5ad2b29dc9d7d6ce3012d5bd6ccbae63d38d675`. It contains 266 indexed triangles, one material and three 1024×1024 maps. The inspected atlas shows the generic Hindi title “पान की दुकान” and painted metal. The frontage position is authored for gameplay.

The separate [Indian Shop model](https://sketchfab.com/3d-models/indian-shop-dad04bbb505443129a86cebd89d77610) by anandmohan662 has a baked photograph with a branded Kirana King storefront and product packaging. The model’s metadata lists CC BY 4.0. Independent permission for the photographed components remains unverified, so the model remains a research candidate.

## Hill Road shutter study

**Rollershutter Door** by **MP**, acquired **24 November 2026** from Poly Haven’s published 1K glTF download. The game GLB retains the clean steel variant with 552 triangles and one material. It embeds 512×512 base color, normal and packed occlusion/roughness/metalness maps resampled from the original 1K textures. The material response is tuned for painted steel, and the mesh is widened in game to fit one closed, fictional Hill Road shop bay. [Original model](https://polyhaven.com/a/rollershutter_door) · [Publisher file manifest](https://api.polyhaven.com/files/rollershutter_door) · [Poly Haven CC0 license](https://polyhaven.com/license)

The repacked runtime GLB is **229,000 bytes**, SHA-256 `3df6cbcf9eda0005744783f92e6861cc4769ea8832d88395a1d209ef0f42c111`. The imported shutter contributes one material surface to the existing frontage mesh.
