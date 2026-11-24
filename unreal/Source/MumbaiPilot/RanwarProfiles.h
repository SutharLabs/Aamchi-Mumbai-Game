#pragma once

#include "CoreMinimal.h"

namespace RanwarProfiles
{
    inline constexpr TCHAR Section[] = TEXT("RanwarPreferences");
    inline constexpr int32 MaxProfiles = 12;

    int32 Load(TArray<FString>& Names);
    void Save(const TArray<FString>& Names, int32 ActiveProfile);
    FString NormalizeName(FString Name);
}
