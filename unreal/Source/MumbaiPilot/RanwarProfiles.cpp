#include "RanwarProfiles.h"

#include "Misc/ConfigCacheIni.h"

FString RanwarProfiles::NormalizeName(FString Name)
{
    Name.TrimStartAndEndInline();
    if (Name.Len() > 32)
    {
        return {};
    }
    for (const TCHAR Character : Name)
    {
        if (Character < 32 || (Character >= 127 && Character <= 159) || Character == 0x200B
            || (Character >= 0x2028 && Character <= 0x202E) || (Character >= 0x2066 && Character <= 0x2069))
        {
            return {};
        }
    }
    return Name;
}

int32 RanwarProfiles::Load(TArray<FString>& Names)
{
    Names.Reset();
    int32 ActiveProfile = 1;
    if (GConfig)
    {
        GConfig->GetArray(Section, TEXT("ProfileNames"), Names, GGameUserSettingsIni);
        GConfig->GetInt(Section, TEXT("ActiveProfile"), ActiveProfile, GGameUserSettingsIni);
    }
    if (Names.IsEmpty())
    {
        Names.Add(TEXT("Player"));
    }
    Names.SetNum(FMath::Min(Names.Num(), MaxProfiles));
    for (int32 Index = 0; Index < Names.Num(); ++Index)
    {
        Names[Index] = NormalizeName(MoveTemp(Names[Index]));
        if (Names[Index].IsEmpty())
        {
            Names[Index] = FString::Printf(TEXT("Player %d"), Index + 1);
        }
    }
    return ActiveProfile >= 1 && ActiveProfile <= Names.Num() ? ActiveProfile : 1;
}

void RanwarProfiles::Save(const TArray<FString>& Names, int32 ActiveProfile)
{
    if (!GConfig)
    {
        return;
    }
    GConfig->SetArray(Section, TEXT("ProfileNames"), Names, GGameUserSettingsIni);
    GConfig->SetInt(Section, TEXT("ActiveProfile"), ActiveProfile, GGameUserSettingsIni);
    GConfig->Flush(false, GGameUserSettingsIni);
}
