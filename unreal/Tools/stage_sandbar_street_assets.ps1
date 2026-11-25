[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ContentRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Exact paths and hashes for the CC0 and CC BY 4.0 packages recorded in docs/THIRD_PARTY.md.
$approvedPackages = [ordered]@{
    'City/Props/Bench/modular_street_seating_armrests_diff_2k.uasset' = '38C9C327E7EAF9511BC72818FF94C6EE0476E1E4D4668D982D391E3C6C158CFB'
    'City/Props/Bench/modular_street_seating_armrests_nor_gl_2k.uasset' = '5D3A2526B0AA7CE7F671B9712A3269BAD58079D78FE9C8A5DFDA23A40ED14BEB'
    'City/Props/Bench/modular_street_seating_armrests_rough_2k.uasset' = 'DC5B03BDDDFCAE59AE2C3F220C65FB9CD1344421DDFDDC31F70E824E167A3F15'
    'City/Props/Bench/modular_street_seating_armrests.uasset' = '56C6C5235098B2749E7F886326F7BD007C6AD079D3E147D703C3BAABAC902042'
    'City/Props/Bench/modular_street_seating_supports_diff_2k.uasset' = '5F86BCD0FC6748EDC9DED3CC243F24CE2EF7EC5B493D39CAA0E54CC9A338A9DD'
    'City/Props/Bench/modular_street_seating_supports_nor_gl_2k.uasset' = '14B357E28BF0AF7D8FD21A8AA89A5C89FA386D86D66A75C4D87A70C80DF5E537'
    'City/Props/Bench/modular_street_seating_supports_rough_2k.uasset' = '9D06DCBD41DCDA14144D424951CAE71DE368F0319B150F6C17102C249C559C22'
    'City/Props/Bench/modular_street_seating_supports.uasset' = '31F2FAF1404D3EFBC0F8040F091875C6B062D4AD549E6DC3195B073525DADD03'
    'City/Props/Bench/modular_street_seating_timber_diff_2k.uasset' = 'FDFA0153A5F588A0C4CD887E5084F0C2539BF126A201BEB90A6ECA98A37AE1D0'
    'City/Props/Bench/modular_street_seating_timber_nor_gl_2k.uasset' = '04C2AD9F1E71BFB33546E01632F0C1F07C4098805492A076372D51F2B2591855'
    'City/Props/Bench/modular_street_seating_timber_rough_2k.uasset' = '96288F25444D0286223C8080CF0E2D766941F87D588937789093942C48FEFAA3'
    'City/Props/Bench/modular_street_seating_timber.uasset' = '9E47FD0E0F8743D86521E6AE5AF7F58DF9BFEC3BCB542C665C77197065C055EC'
    'City/Props/Bench/SM_Bench.uasset' = '2697776156C6DCF0FF1282FAA7D5FC16CC0CE7970BE26AF135C28EDEE3A46BFE'
    'City/Props/UtilityBox/SM_UtilityBox.uasset' = '5F6CD9552D82340BEE94FB191DB4E70D051AFDB4505C39CDAD51B53B34C71D32'
    'City/Props/UtilityBox/utility_box_02_diff_2k.uasset' = 'C64E05AFA01B447052AD7B423FA212DB99EFF8C68EB7C5FA6C1FFECD6CC0EE72'
    'City/Props/UtilityBox/utility_box_02_nor_gl_2k.uasset' = 'FB7B6E4BBA710E58341122A6A530A0A4E977E618E400F9E3A7C910C937D1C895'
    'City/Props/UtilityBox/utility_box_02_rough_2k.uasset' = '94F5CFDA742B1646B1A23CD7BB82B2EE72D7D438EB9BEF99829D166904C1594E'
    'City/Props/UtilityBox/utility_box_02.uasset' = '475C47A6EF964F0DF370268481F659CECFCBDD84AF195A175F9A9C91BC1FD30D'
    'City/Textures4k/concrete_tile_facade/T_concrete_tile_facade_4k_Diffuse.uasset' = 'B7B41D8CC74F17816D14057DC4FCD40CABDEA92F1B57DB90188C6CAA3EB01612'
    'City/Textures4k/concrete_tile_facade/T_concrete_tile_facade_4k_Normal.uasset' = '4192A93ECE13A6E38A513EA9DEF4BD83477BC6A40439F49DC142BA6E2BA8E16D'
    'City/Textures4k/concrete_tile_facade/T_concrete_tile_facade_4k_Rough.uasset' = '7327CD8893FCF2F97D4CDD9E7A97075B0C7ACAD6F02B1C390A90376A91CCF6E4'
    'City/Textures4k/concrete_pavement_03/T_concrete_pavement_03_4k_Diffuse.uasset' = 'DB5A455C9F83A6D9B1E650448934C2391FFBBC556407902D2168BFA47767EED5'
    'City/Textures4k/concrete_pavement_03/T_concrete_pavement_03_4k_Normal.uasset' = '54551FAA2BAFF0C219EFE31B03A1FFBEFC04B24D648BB3FFAA10E2A5A327A7CB'
    'City/Textures4k/concrete_pavement_03/T_concrete_pavement_03_4k_Rough.uasset' = '04592F0ED724B1A2685D48E608CB02DF3363A38E0C92F55578C98B97FAEF4BAA'
    'City/Textures4k/plastered_wall_02/T_plastered_wall_02_4k_Diffuse.uasset' = 'B14FE5A0321C1D86B97D069D40022904097BCFF69D25A8C10F939AEFFF18BFFE'
    'City/Textures4k/plastered_wall_02/T_plastered_wall_02_4k_Normal.uasset' = '22551E7C2C083574C6361F79FAC8D10B1D0FBF607A1576A67AB2183FCDE5495E'
    'City/Textures4k/plastered_wall_02/T_plastered_wall_02_4k_Rough.uasset' = 'CE2B51AFF31C0BAC8A728602F878698671E7A143C5708CC91A1757962B0EB66A'
    'City/Textures4k/white_stucco/T_white_stucco_4k_Diffuse.uasset' = 'E4680425E0C01C1C43988907AEEB42DCC6C97DB2E953DED4ADB8CDC0DF146885'
    'City/Textures4k/white_stucco/T_white_stucco_4k_Normal.uasset' = '42F91D022BE74461BF32646F0EE1B22F19D4999737B1321A4F17D97192A74981'
    'City/Textures4k/white_stucco/T_white_stucco_4k_Rough.uasset' = '39CBCBCC4361EAF3E6636DC52349148CDCD49B9D3D5FC4DC2BA4790227B63A87'
    'Decals/Textures/T_Decal_Leaking012A.uasset' = '5CF97024227EB0C3A5ECE514D9E242CD19746138061D1A0FD4874D48BD4B02B6'
    'Decals/Textures/T_Decal_Leaking016A.uasset' = 'EBB88DC7C009E0E397EA8FF1DFDF0120D54D9BB3A3A33133821CAF472ACEDE7F'
    'Decals/Textures/T_Decal_Leaking017A.uasset' = '2433B7F385D65022C46CE4731341480E42BECBFDD40D6AC548CF0D94D5C9847A'
    'Decals/Textures/T_Decal_Leaking019A.uasset' = 'C55698A4B7FD41B903A22E9C5DA26AB9AF2E0B9336609030E8D87DBCF50A0E4C'
    'Sketchfab/Awning/Awning/Materials/Awning.uasset' = '72D5CE5692AD9E3F2C08D94837430BCED54B07B3BD0DCD9EE342118DED6B3AD4'
    'Sketchfab/Awning/Awning/StaticMeshes/Awning.uasset' = '8B25318EE5E9FA2AB3F3C041713382C91F2F6C38B36DDC945E5B2956BBCEBB1D'
    'Sketchfab/Awning/Awning/Textures/Awning_texture_0.uasset' = '73D23B15928E3BCDD3827465FFA0B3D1695A4A8AFD98041F0261E318439FC7A8'
    'Sketchfab/Awning/Awning/Textures/Awning_texture_1.uasset' = '8ED256691C132647509EFF12C5F8C5ED09B51DC8FAC90EC7A08C339566E96C6A'
    'Sketchfab/Awning/Awning/Textures/Awning_texture_2.uasset' = 'C33409BD196A0C5360B781440442EA3EC6FAFB9DBEC9179DB743CA25DC09FF81'
    'Sketchfab/Condenser/Condenser/Materials/material_0.uasset' = 'B52C6FB103B14FF755F1BE3CA8887719D98B2271252DFC3A4BC7B64EB3C45323'
    'Sketchfab/Condenser/Condenser/Textures/Condenser_texture_0.uasset' = '670017614CE4CAC23EEAF497F755159B3614F3FCFE5927B4F726DCE739CCDBA5'
    'Sketchfab/Condenser/Condenser/Textures/Condenser_texture_1.uasset' = '1DCB966E70B4B429F7EA1F44B37B165A6D29E8CB9AF66BCDC93A356892A31B79'
    'Sketchfab/Condenser/Condenser/Textures/Condenser_texture_2.uasset' = 'B4FC4F224983D3434CE3F41A82F1D4CBEE1623C06E177BB045F1342A019619A3'
    'Sketchfab/Condenser/Condenser/Textures/Condenser_texture_3.uasset' = 'A833F70E00F95809CDAE609FA8E9F07410BD8FF75C2F8C03F60D068A2E51537D'
    'Sketchfab/HVAC/HVAC/Materials/material39.uasset' = '3FF32C8EEA14081D30958894AA08B2AD1924677F5F43C7707FDA50FB15B442D2'
    'Sketchfab/HVAC/HVAC/Textures/HVAC_texture_3.uasset' = '29CB573D168E137ECA1B0925CD3A7DDA45222BB4B87D19086EC7DE364684601B'
    'Sketchfab/HVAC/HVAC/Textures/HVAC_texture_4.uasset' = 'CBFDA407D258A3CCF07B962973D8CA4FC94D05C76C2A17C41C945F16D16A4EA1'
    'Sketchfab/HVAC/HVAC/Textures/HVAC_texture_5.uasset' = '632B53FEC9C0C6562C4A7127561DE4673F05A319795E8A03E5A93A56E9B3FD58'
    'Sketchfab/IndustrialAC/IndustrialAC/Materials/AC-Unit_MTL.uasset' = '68CE10B1AD3BE709F9D88ECA69D1F86C007810426FF0F0638B4AC820032AC2BA'
    'Sketchfab/IndustrialAC/IndustrialAC/Textures/IndustrialAC_texture_0.uasset' = 'EA800B7DE013AA68A8EA69E23700534B4B78CF633F3F855731A3403078F09B04'
    'Sketchfab/IndustrialAC/IndustrialAC/Textures/IndustrialAC_texture_1.uasset' = '38519786678B69DD1F9EC29822EE63353703C7C80D6CD482B0784B75F97943A1'
    'Sketchfab/IndustrialAC/IndustrialAC/Textures/IndustrialAC_texture_2.uasset' = '94062209C1F6D2898F21E9AA9F4531F4B59E1DCCB8333E484038CCD244D08A8B'
    'Sketchfab/Roof/SM_Condenser.uasset' = '50E4FE3E51D499CB80F5631644394CD15B32390E0A46C89E04C78F53B6BF4904'
    'Sketchfab/Roof/SM_HVAC.uasset' = '94E7A06613D9A043E7BE7FADE5B9002FA29D0446E4C5593AD203F7263BAFC6E9'
    'Sketchfab/Roof/SM_IndustrialAC.uasset' = 'AD9510E17066140B9C695EBF456B535457A73F00FB191592D4085FAA599E078B'
    'Sketchfab/Roof/SM_SatDish.uasset' = '5C04C6DA337C496F142259897F5633EF9CA8C0D5D407C3D2EC94C91C7A1A38C6'
    'Sketchfab/Roof/SM_VentChimney.uasset' = '354E49E59F9D1777B2CCE4C5A100900EBE987374E6778B709CE2C32234C8B00B'
    'Sketchfab/Roof/SM_VentUnitC.uasset' = 'A25A91BF4533B40F665A2525EE5487A38381D1A8A6B8BAB4FECD219E55D41B39'
    'Sketchfab/RoofVentKit/RoofVentKit/Materials/HVAC_AirductA.uasset' = '935BE0F28379A9E38CB6DFC17635745AE3889F091FD12B3D489014ECC02CB4CB'
    'Sketchfab/RoofVentKit/RoofVentKit/Materials/HVAC_AirductB.uasset' = '12C382F15910F2731B14101952F5D019B686192797E8081908763C678B22DCFA'
    'Sketchfab/RoofVentKit/RoofVentKit/Materials/HVAC_AtlasTexture.uasset' = '537B7F487550FC71ADD61B1969EF01A4842F7C2DEBF9EEF7194E43987D2642EC'
    'Sketchfab/RoofVentKit/RoofVentKit/Materials/HVAC_Chimney.uasset' = '57956331114FCFB01685DDB9AE00EC5B4DFF45AC7CB6743732480A3EB3FA1143'
    'Sketchfab/RoofVentKit/RoofVentKit/Materials/HVAC_PanelsC.uasset' = '2A866CD56F41531B40905EAB2B4D003C0DEC4F2273B1E0872A52135081BF02EC'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_10.uasset' = 'C3C4B34EAEF251D12A8FE8C6258B4B1B8B3206CAF20EC837D8CADAE3A085F17C'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_11.uasset' = '863C2F46A7E1C15ECC764397B4F2594F1C64440EE646A61DBF9723EE459BAD9D'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_12.uasset' = 'C14DEA9FFD01CF3137ACD5B6D263D3BC99AD2D81AF8C0185371C9AB83C73A7E4'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_18.uasset' = 'A5CC748FDEA676E1F4F0FF9EFDA63754085FAD9ECBCD43CB5540D5EB501DCE4B'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_19.uasset' = '5848477688DAE495D39404F8547966283A62EBF8C52C6AEABB1BD7A0879C7B0C'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_20.uasset' = '4FD04485B2CB91D1B85B5320970A16969C875A02564A97E291D43267DAC358D2'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_21.uasset' = '80F5828A78F99CAD8BCC8F03CE9988A07EB2F50F168E17F936D601CAE891D9EC'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_22.uasset' = '43229BA96F4124EC981172D487C015243FE806514D09AE8C4D47F3147E4D3946'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_23.uasset' = '34CB8F4DA7777B30333CC9F460BF7AC3C716E69456BCEF715D120B96F9AFFC77'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_24.uasset' = 'DD59259C623AD43F8F73F3A7059A5772989B8C8D08E597D10CD47D655BD745C3'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_25.uasset' = '9780E61D04EE0324FEE47DBC2658267239B2CF29BF85E22F80E7E04B266E8B71'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_26.uasset' = '3F38EF47A6847E831E8ADCA91C8EC57BE3DB513F50B27F227E92DC8B1095FBA3'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_27.uasset' = '8BEFF9E8B0F284E839717EF941E54CE5D0EBBD06AEADA6D439B2943AEEE9CD31'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_28.uasset' = '3F5E108DE5D95B1E0199FA2A60EEC0B316A213C40FBEF8A6CD595435312386EF'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_29.uasset' = '0874983772AA47137C82F83FFF8C5FAEBD8D1C641E5684C662865265C3158E41'
    'Sketchfab/RoofVentKit/RoofVentKit/Textures/RoofVentKit_texture_9.uasset' = 'BCAA37978747A859220B5F34F229764C8636CD771089ADD2949E883FCF3AFD90'
    'Sketchfab/SatDish/SatDish/Materials/Checker.uasset' = '71DFF2133639B9F6C13C7487DCF3F9EC0B40B5F3FC9E5C7CF6911EC667FB38E3'
    'Sketchfab/SatDish/SatDish/Textures/SatDish_texture_0.uasset' = '0A994E00ED5597684CF470B3AB8C2F22A643D717A009E275BECA10F75E04818A'
    'Sketchfab/SatDish/SatDish/Textures/SatDish_texture_1.uasset' = 'B0AFE4D01501ABA8551A8EE7E18CF53CD11D4C316E024EB5B23CEA3FFDBB5B60'
    'Sketchfab/SatDish/SatDish/Textures/SatDish_texture_2.uasset' = '7EE5CCCA1CDD64A91343D09332F508B7F96F90A136A18AFD9CF42AB11140F0DF'
}

function Get-PackagePath([string]$Root, [string]$RelativePath) {
    $separator = [IO.Path]::DirectorySeparatorChar
    $prefix = $Root.TrimEnd($separator) + $separator
    $fullPath = [IO.Path]::GetFullPath([IO.Path]::Combine($Root, $RelativePath))
    if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Package path is outside its content root: $fullPath"
    }
    return $fullPath
}

function Assert-NoReparsePoints([IO.FileSystemInfo]$Item) {
    while ($null -ne $Item) {
        if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Asset staging requires an ordinary file-system path: $($Item.FullName)"
        }
        if ($Item -is [IO.FileInfo]) {
            $Item = $Item.Directory
        } else {
            $Item = $Item.Parent
        }
    }
}

function Get-ExistingPathItem([string]$Path) {
    try {
        Get-Item -LiteralPath $Path -Force
    } catch [System.Management.Automation.ItemNotFoundException] {
        return $null
    }
}

$sourceDirectory = Get-Item -LiteralPath $ContentRoot -Force
$targetDirectory = Get-Item -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'Content') -Force
foreach ($directory in $sourceDirectory, $targetDirectory) {
    if ($directory -isnot [IO.DirectoryInfo]) {
        throw 'The source and destination content roots must be file-system directories.'
    }
    Assert-NoReparsePoints $directory
}
if ($sourceDirectory.FullName -eq $targetDirectory.FullName) {
    throw 'The provided Content root must be the separate SandbarCity source directory.'
}

# Check every expected source and destination before creating any directories or copying files.
$copies = foreach ($package in $approvedPackages.GetEnumerator()) {
    $source = Get-PackagePath $sourceDirectory.FullName $package.Key
    $target = Get-PackagePath $targetDirectory.FullName $package.Key
    $sourceItem = Get-Item -LiteralPath $source -Force
    if ($sourceItem -isnot [IO.FileInfo]) {
        throw "Expected an Unreal package file: $source"
    }
    Assert-NoReparsePoints $sourceItem
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $package.Value) {
        throw "Source package differs from the reviewed SandbarCity asset: $source"
    }

    $targetItem = Get-ExistingPathItem $target
    if ($null -ne $targetItem) {
        Assert-NoReparsePoints $targetItem
        if ($targetItem -isnot [IO.FileInfo] -or
            (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $package.Value) {
            throw "A different item occupies an approved Unreal package path: $target"
        }
        continue
    }

    $parentPath = [IO.Path]::GetDirectoryName($target)
    do {
        $existingParent = Get-ExistingPathItem $parentPath
        $parentPath = [IO.Path]::GetDirectoryName($parentPath)
    } until ($null -ne $existingParent)
    if ($existingParent -isnot [IO.DirectoryInfo]) {
        throw "Expected a directory above the Unreal package: $($existingParent.FullName)"
    }
    Assert-NoReparsePoints $existingParent
    [PSCustomObject]@{ Source = $source; Target = $target; Hash = $package.Value }
}

$installed = 0
foreach ($copy in $copies) {
    $targetParent = [IO.Path]::GetDirectoryName($copy.Target)
    $null = [IO.Directory]::CreateDirectory($targetParent)
    Assert-NoReparsePoints (Get-Item -LiteralPath $targetParent -Force)
    $temporaryPath = Join-Path $targetParent ('.sandbar-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::Copy($copy.Source, $temporaryPath, $false)
        if ((Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash -ne $copy.Hash) {
            throw "Source package changed during staging: $($copy.Source)"
        }
        # A same-volume move installs the verified bytes without replacing an existing file.
        [IO.File]::Move($temporaryPath, $copy.Target)
        $installed++
    } finally {
        [IO.File]::Delete($temporaryPath)
    }
}

Write-Output "SandbarCity packages installed: $installed. Already present: $($approvedPackages.Count - $installed)."
