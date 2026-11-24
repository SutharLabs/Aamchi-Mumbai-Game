# Character material and geometry sources

Acquired and adapted on **23 November 2026**. One opaque material uses two 1024 × 1024 atlases with mipmaps. The clothing silhouettes, trim, colors, shoes, rig, and hairline cuts are authored for the Ranwar cast. The head, clothing and shoes still share one skinned mesh surface per character.

| Shipped file | Upstream input and license | Adaptation |
| --- | --- | --- |
| `head_mesh.obj` | [MakeHuman base mesh](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj) · [CC0 1.0 asset grant](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md). The file header credits Data Collection AB, Joel Palmius, and Jonas Hauquier. | Cropped the body surface to the head and upper neck, converted to the game's rest pose and scale, and decimated to 3,474 triangles in Blender 5.3. The game uses the original UV coordinates and fits the head to each cast silhouette. |
| `civilian_surface.png` | `skins/young_asian_male/young_lightskinned_male_diffuse3.png` and its CC0 declaration in `young_asian_male.mhmat` from the [MakeHuman CC0 system-asset pack](https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip). [Poly Haven Stretch Poplin diffuse](https://polyhaven.com/a/stretch_poplin) is by Rico Cilliers and colormass under [CC0 1.0](https://polyhaven.com/license). | Masked the skin diffuse to the mapped head and upper neck, resized the diffuse, normalized the cotton map for the wardrobe colors, and added original cropped-hair grain. |
| `civilian_normal.png` | [Poly Haven Stretch Poplin OpenGL normal](https://polyhaven.com/a/stretch_poplin), Rico Cilliers and colormass, [CC0 1.0](https://polyhaven.com/license). | Resized and tiled the cotton normals to the fabric section. Other regions use a flat normal. |

Upstream head geometry SHA-256 `8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c`. Upstream skin diffuse SHA-256 `f50016a5507fc687dc8df06599c8ea48de950cd185de33a71cafc1319ddab4d5`. The downloaded 1K Poplin JPEG matches Poly Haven's published API checksums `03f707a3a0367d2cd3fa90b71eec4b89` for diffuse and `930a92aa642c2c4c196cc8c9d26bf65d` for the GL normal.

## Ranwar cast refinement

The shared mesh uses deeper-set globes under the existing eyelids, brown iris detail, tapered brows, less exaggerated hair and shoulder silhouettes, and subtler complexion and lip variation. The visible kurta and dupatta use the established materials and rig weights. Ravi and Kavita have original named presets in both engines. The edited details share the existing atlases and one material surface. [Shared character mesh](../player_character.gd) · [Unreal exchange](../../../unreal/ContentSource/RANWAR_STREET.md)

Matched Godot Compatibility captures on Intel Iris Xe examined Omkar in a walk pose and the male and female silhouettes at street distance and in close-up. The Omkar GLB has 7,692 triangles after the refinement, up from 7,244. Verification confirmed the same 21 joint transforms, inverse bind matrices and byte-identical idle, walk and run samples. The eight posed contact GLBs each preserve one material section and a floor-level origin. The run foot check recorded 2 mm of planted forefoot drift.
