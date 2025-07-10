// Copyright Druid Mechanics

#pragma once

#include "CoreMinimal.h"
#include "Components/ProgressBar.h"
#include "UObject/Object.h"
#include "AngelScriptProgressBar.generated.h"

/**
 * 
 */
UCLASS(Meta = (ScriptMixin = "UProgressBar"))
class AURA_API UAngelScriptProgressBar : public UObject
{
	GENERATED_BODY()
public:
	UFUNCTION(ScriptCallable)
	static void SetWidgetStyle(UProgressBar* ProgressBar, FProgressBarStyle& InStyle)
	{
		ProgressBar->SetWidgetStyle(InStyle);
	}
};
