# Character material and geometry sources

Acquired and adapted on **23 November 2026**. The civilian presets use two 1024 × 1024 atlases with mipmaps. The clothing silhouettes, trim, colors, shoes, rig, and hairline cuts are authored for the Ranwar cast. The head, clothing and shoes share one skinned mesh surface per character.

| Shipped file | Upstream input and license | Adaptation |
| --- | --- | --- |
| `head_mesh.obj` | [MakeHuman base mesh](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj) · [CC0 1.0 asset grant](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md). The file header credits Data Collection AB, Joel Palmius, and Jonas Hauquier. | Cropped the body surface to the head and upper neck, converted to the game's rest pose and scale, and decimated to 3,474 triangles in Blender 5.3. The game uses the original UV coordinates and fits the head to each cast silhouette. |
| `civilian_surface.png` | `skins/young_asian_male/young_lightskinned_male_diffuse3.png` and its CC0 declaration in `young_asian_male.mhmat` from the [MakeHuman CC0 system-asset pack](https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip). [Poly Haven Stretch Poplin diffuse](https://polyhaven.com/a/stretch_poplin) is by Rico Cilliers and colormass under [CC0 1.0](https://polyhaven.com/license). | Masked the skin diffuse to the mapped head and upper neck, resized the diffuse, normalized the cotton map for the wardrobe colors, and added original cropped-hair grain. |
| `civilian_normal.png` | [Poly Haven Stretch Poplin OpenGL normal](https://polyhaven.com/a/stretch_poplin), Rico Cilliers and colormass, [CC0 1.0](https://polyhaven.com/license). | Resized and tiled the cotton normals to the fabric section. Other regions use a flat normal. |

Upstream head geometry SHA-256 `8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c`. Upstream skin diffuse SHA-256 `f50016a5507fc687dc8df06599c8ea48de950cd185de33a71cafc1319ddab4d5`. The downloaded 1K Poplin JPEG matches Poly Haven's published API checksums `03f707a3a0367d2cd3fa90b71eec4b89` for diffuse and `930a92aa642c2c4c196cc8c9d26bf65d` for the GL normal.

## Ranwar cast refinement

The shared mesh uses deeper-set globes under the existing eyelids, brown iris detail, tapered brows, less exaggerated hair and shoulder silhouettes, and subtler complexion and lip variation. The visible kurta and dupatta use the established materials and rig weights. Ravi and Kavita have original named presets in both engines. The edited details share the existing atlases and one material surface. [Shared character mesh](../player_character.gd) · [Unreal exchange](../../../unreal/ContentSource/RANWAR_STREET.md)

Matched Godot Compatibility captures on Intel Iris Xe examined Omkar in a walk pose and the male and female silhouettes at street distance and in close-up. The Omkar GLB has 7,692 triangles after the refinement, up from 7,244. Verification confirmed the same 21 joint transforms, inverse bind matrices and byte-identical idle, walk and run samples. The eight posed contact GLBs each preserve one material section and a floor-level origin. The run foot check recorded 2 mm of planted forefoot drift.

## Omkar player redesign

Updated **24 November 2026**. Omkar’s indigo sadara has a more fitted waist, shorter sleeves, a pocket and a curved back yoke. The sleeves share weighted vertices with cut armholes in the torso. The ivory dhotar has narrower cuffs and an inset pleat at the waist. Both original hand meshes have individually shaped fingers and reuse the established hand and forearm bones. The face reuses the documented MakeHuman geometry, with an adjusted jaw, cheek and swept crown. [Character mesh](../player_character.gd) · [Hand geometry](../omkar_hand.gd)

| Runtime atlas | Derivation |
| --- | --- |
| `omkar_surface.png` | Reuses the original CC0 face diffuse with tuned skin color, a continuous cropped-hair grain and padded edge texels. Cotton and neutral swatches match the civilian atlas. |
| `omkar_normal.png` | Adds light skin pore and jaw detail to the head UV region. The existing Poly Haven cotton normal pixels are identical to the civilian texture. |
| `omkar_roughness.png` | Authored grayscale mask for separate skin, scalp and cotton responses in one material. The glTF exchange embeds roughness in its packed metallic-roughness map. |

The player GLB has 8,384 triangles, one skinned surface and three embedded 1024 × 1024 maps. Its 21 joint transforms, inverse bind matrices and idle, walk and run samples match the prior export byte-for-byte. The rendered Godot checks cover the close portrait, walking camera, scooter rider, run support and airborne clearance, jump and impact recovery. The head follows the body animation and has a fixed facial expression. Physical-device performance remains open.

## SandbarCity scan adaptation for the default Omkar

The SandbarCity authoring packages contain two Renderpeople models licensed under CC BY 4.0. Unreal's skeletal glTF exporter produced the donor geometry locally, and Blender fitted and baked the selected pieces. The game uses its existing facial mesh and complexion, Maharashtrian wardrobe, and 21-joint player rig.

| Shipped detail | Donor and adaptation |
| --- | --- |
| `omkar_scan_hand.res` | [Eric Rigged 001 by Renderpeople](https://sketchfab.com/3d-models/eric-rigged-001-rigged-3d-business-man-a46bc9f67aaa415bb4f3241eef900e7f) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Isolated 1,293 triangles from the rigged scan's right hand and added 35 bridging triangles to fit the ten-point forearm boundary. The left hand mirrors the fitted mesh. Both inherit the existing wrist and forearm weights. |
| `omkar_surface.png`, `omkar_normal.png`, `omkar_roughness.png` | [Nathan Animated 003 by Renderpeople](https://sketchfab.com/3d-models/nathan-animated-003-walking-3d-man-143a2b1ea5eb4385ae90a73657aca3bc) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Sampled 367 torso triangles and the corresponding textured surface to bake fabric folds. The new sadara UV rectangle retains the indigo tint and cotton roughness. Existing atlas regions preserve their pixel values. |

Only the built-in Omkar look uses these derivatives. The optional character creator continues to use its original wardrobe UVs and hand geometry.

The updated player GLB contains 10,180 triangles in one skinned surface. Both wrists weld to the existing forearms at ten shared edge positions. The head positions and UVs, all 21 joint transforms and inverse binds, and all three locomotion clips match the earlier player exchange.

## Omkar's fitted scan head

Updated **25 November 2026**. The built-in Omkar uses a fitted head and short hair from [Renderpeople's Eric Rigged 001](https://sketchfab.com/3d-models/eric-rigged-001-rigged-3d-business-man-a46bc9f67aaa415bb4f3241eef900e7f), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), supplied in the SandbarCity source. Blender aligned the head to Omkar's rest pose, removed the donor clothing, and extended the neckline below the sadara collar. The scan provides the eye, stubble, ear and swept hair detail.

| Shipped file | Changes |
| --- | --- |
| `omkar_scan_head.obj` | Fitted 8,976 triangles and extended the neck rim. The head uses Omkar's existing Head, Neck, and Chest bones. |
| `omkar_scan_surface.png`, `omkar_scan_normal.png`, `omkar_scan_roughness.png` | Cropped and resized the source maps into the head portion of the existing 1024 × 1024 atlas. Adjusted skin tint, reduced normal-map strength, and authored the roughness response. |

The exchange has 15,042 triangles in one skinned material section and three 1024 × 1024 maps. The 21 joint transforms, inverse binds and idle, walk, and run samples match the prior exchange byte for byte. The body vertices below the collar also match. The scan keeps a fixed facial expression and applies only to the built-in Omkar. [Character mesh](../player_character.gd)


## Character creator

Updated **24 November 2026**. Omkar and Ira are fictional protagonists sculpted in Godot on the existing CC0 head and 21-joint rig. The public portraits were visual studies for the side-swept crown and subtle lower-face grooming, the softer cheek-to-jaw transition, and the tied-back shape with temple framing. The in-game geometry, texture atlas and scripted dialogue use the project sources documented here. [Riteish Deshmukh festival portrait](https://mami.mumbaifilmfestival.com/media/1278/mami_festival_catalogue-2018.pdf#page=20) · [Sai Tamhankar production still](https://www.netflix.com/tudum/articles/dabba-cartel-release-date-news) · [Sonalee Kulkarni portfolio](https://yogeentertainment.com/artists/Sonalee-Kulkarni)

The creator offers six hair shapes and three outfits per protagonist, for 36 combinations. The wardrobe mixes traditional sadara and dhotar, kurta pairings, and contemporary shirts and trousers. Salon references informed the bun, braid, waves and parted styles. [Lakmé Salon style reference](https://www.lakmesalon.in/blogs/all/4-easy-to-do-hairstyles-that-you-can-easily-pull-off-this-karwa-chauth) · [Fabindia kurta reference](https://www.fabindia.com/collections/women-kurtas-and-kurtis)

The full combination sweep produced 4,336 to 5,705 indexed vertices per look and checked distinct geometry, one skinned surface and normalized weights on the shared skeleton. A continuous skin surface joins the head boundary to the collar. The same appearance reaches the locomotion rig and the seated driver and rider rig in all four vehicle families. The portraits retain stylized contours and garment folds. [Character creator checks](../../tests/avatar_creator_smoke.gd) · [Dialogue sources](../../shared/dialogue/SOURCES.md)
