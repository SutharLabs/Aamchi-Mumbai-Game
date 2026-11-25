# Ranwar surface textures

Imported 23 November 2026 from Poly Haven. The photograph-based tiles are representative material finishes. Exact local wall colours, repair patterns and parcel finishes remain for review against current Ranwar photographs. All six source assets are published under CC0 1.0. [Poly Haven license](https://polyhaven.com/license) · [CC0 legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode)

| Game file | Poly Haven source and author | Use and repeat width |
| --- | --- | --- |
| `asphalt.webp`, `asphalt_normal.png` | [Asphalt 02](https://polyhaven.com/a/asphalt_02) · Rob Tuytel | Road, junction, recovery yard and vehicle bays, 3 m |
| `concrete.webp`, `concrete_normal.png` | [Concrete Floor Worn 02](https://polyhaven.com/a/concrete_floor_worn_02) · Dimitrios Savva | Footway, sidewalks, curbs, ramp and plinths, 2 m |
| `plaster.webp`, `plaster_normal.png` | [Concrete Wall 003](https://polyhaven.com/a/concrete_wall_003) · Dimitrios Savva and Rico Cilliers | Painted plaster and compound walls, 3 m |
| `clay_tile.webp` | [Roof 09](https://polyhaven.com/a/roof_09) · Rob Tuytel | Weathered terracotta roofing, 4 m |
| `timber.webp` | [Weathered Brown Planks](https://polyhaven.com/a/weathered_brown_planks) · Dimitrios Savva and Rico Cilliers | Stairs, posts and rails, 1.8 m |
| `gravel.webp` | [Sandy Gravel](https://polyhaven.com/a/sandy_gravel) · Charlotte Baglioni | Exposed ground beside roads and around buildings, 2.1 m |

The game includes 512×512 derivatives of the 1K Diffuse maps and three Normal (GL) maps. Diffuse maps use WebP. Normal maps use PNG. Plaster is desaturated and level-adjusted to keep the project's house paint colours. The import settings generate mipmaps and keep the textures available to the desktop and Android Compatibility renderer. These assets are loaded from the local game package.

## Hill Road surface pass

The ambientCG photogrammetry files were retrieved on 23 November 2026. The source service dedicates the downloadable maps to the public domain under CC0 1.0. Use the original scan pages to inspect the materials and the full source ZIPs. These scans provide material appearance and scale for the authored Ranwar model. Current site inspection owns exact paving, wear and paint matches. [ambientCG license](https://docs.ambientcg.com/license/) · [CC0 legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode)

| Original source and archive SHA-256 | Game derivatives | Use and repeat width |
| --- | --- | --- |
| [Asphalt 033](https://ambientcg.com/a/Asphalt033), `Asphalt033_1K-JPG.zip`, `c71801b342dbea594dbdd0bd2ddc0a6d13f813c923fca408b9f5b9ee5e58aba2` | `rainwear_asphalt.webp`, `rainwear_asphalt_normal.png` | Hill Road, junctions and paved recovery bays. 2.5 m world repeat, matching the scan scale. The color derivative blends the ambientCG aggregate with the earlier Poly Haven Asphalt 02 diffuse to retain edge cracks. |
| [Paving Stones 152](https://ambientcg.com/a/PavingStones152), `PavingStones152_1K-JPG.zip`, `48b5d94dcac43659cdc70b223c0066aa7e0bcbb52d2dad19c0ac3b3be51bb3fd` | `hill_road_pavers.webp`, `hill_road_pavers_normal.png` | Sidewalk and shelter paving. 1.3 m world repeat, matching the scan scale. |
| [Painted Plaster 006](https://ambientcg.com/a/PaintedPlaster006), `PaintedPlaster006_1K-JPG.zip`, `fd622afe5f601f3f31eb5c1ab1484dba99b698b857d70b7820a31d7275f74ded` | `weathered_paint.webp`, `weathered_paint_normal.png` | Shallow chips in painted facades. Use a 3 m projected repeat for the existing frontage UVs. The walls use the color derivative with their authored base tints. The normal map is used by the box-based wall finishes. |

The color maps use desaturated 512 × 512 WebP derivatives. Plaster is level-adjusted to stay under the building palette. The positive-Y normal maps use 512 × 512 PNG with their XY relief attenuated to avoid deep-looking grooves. Godot imports mipmaps and uses the Compatibility renderer. The existing Blender exchange preserves projected world-space UVs and converts the color maps to PNG. Unreal uses the same asset colors and applies the established positive-Y normal conversion. [Ranwar scene exchange](../../../unreal/ContentSource/RANWAR_STREET.md)

## Hill Road Tea Room lettering

`hill_road_tea_room_signs.png` is an original 1024 × 512 opaque atlas for the fictional Tea Room tenant. It combines a painted Marathi and English fascia, a posted menu, and a smaller window notice. The lettering is shaped and baked using the project's existing Noto Sans Devanagari font. The frontage mesh maps all three panels to one material slot in Godot and Unreal. [Font license](../../startup/art/NotoSansDevanagari-OFL.txt)
