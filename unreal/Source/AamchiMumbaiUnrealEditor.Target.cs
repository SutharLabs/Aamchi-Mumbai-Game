using UnrealBuildTool;

public class AamchiMumbaiUnrealEditorTarget : TargetRules
{
    public AamchiMumbaiUnrealEditorTarget(TargetInfo target) : base(target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("MumbaiPilot");
    }
}
