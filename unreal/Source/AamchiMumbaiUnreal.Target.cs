using UnrealBuildTool;

public class AamchiMumbaiUnrealTarget : TargetRules
{
    public AamchiMumbaiUnrealTarget(TargetInfo target) : base(target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("MumbaiPilot");
    }
}
