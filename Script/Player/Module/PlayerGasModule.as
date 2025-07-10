
class UPlayerGasModule : UPlayerModuleBase
{
    // private TMap<FName, float32> CachedAttributeValues;
    // private UAuraAttributeSet AttributeSet;

    void Init() override
    {
        Super::Init();

        AAuraCharacter Character = this.OwnerMgr.GetOwnerCharacter();
        // UAngelscriptAbilitySystemComponent ASC = Character.AbilitySystem;

        // ASC.OnAttributeSetRegistered(this, n"OnAttributeSetRegistered");

        // // This is how we register an attribute set with an actor.
        // AttributeSet = Cast<UAuraAttributeSet>(ASC.RegisterAttributeSet(UAuraAttributeSet.Get()));
        // ASC.InitAbilityActorInfo(Character, Character);

        APlayerController PlayerController = Character.GetLocalViewingPlayerController();
        // APlayerController PlayerController = Cast<APlayerController>(Character.GetController());
        if (PlayerController != nullptr)
        {
            auto AuraHUD = Cast<AAuraHUD>(PlayerController.GetHUD());
            if (AuraHUD != nullptr)
            {
                AuraHUD.InitHUDWidget(Character);
            }
        }
    }

    UAngelscriptAbilitySystemComponent GetASC()
    {
        return this.OwnerMgr.GetOwnerCharacter().AbilitySystem;
    }

    // UFUNCTION()
    // void OnAttributeSetRegistered(UAngelscriptAttributeSet NewAttributeSet)
    // {
    // 	UAuraAttributeSet AuraAttributeSet = Cast<UAuraAttributeSet>(NewAttributeSet);
    // 	if (AuraAttributeSet == nullptr) {
    // 		Print(f"OnAttributeSetRegistered {NewAttributeSet.Name} is not UAuraAttributeSet");
    // 		return;
    // 	}

    // 	AuraAttributeSet.InitAttributesMapping();

    // 	// Print(f"OnAttributeSetRegistered {NewAttributeSet.Name}");

    // 	UAngelscriptAbilitySystemComponent ASC = this.GetASC();

    // 	// 不知道为什么这种方法不生效，下面的方法是自己翻源码时翻到的，试了下是生效的，但每次只能注册一个属性
    // 	// ASC.RegisterAttributeChangedCallback(AttributeSetClass, n"Health", this, n"OnAttributeChanged");

    // 	ASC.OnAttributeChanged.AddUFunction(this, n"OnAttributeChanged");

    // 	// 看C++源码，这样注册下才会回调到OnAttributeChangedTrampoline里，这里才会Broadcast
    // 	UClass AttributeSetClass = AuraAttributeSet.GetClass();
    // 	for (auto Element : AuraAttributeSet.GetAllAttributes())
    // 	{
    // 		FName AttributeName = Element.Key;
    // 		ASC.RegisterCallbackForAttribute(AttributeSetClass, AttributeName);
    // 	}
    // }

    // UFUNCTION()
    // private void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData)
    // {
    // 	CachedAttributeValues.Add(AttributeChangeData.Name, AttributeChangeData.NewValue);
    // 	AuraUtil::GameInstance().EventMgr.OnAttributeChangedEvent.Broadcast(AttributeChangeData);
    // }

    // float32 GetAttributeValue(FName AttributeName)
    // {
    // 	if (!CachedAttributeValues.Contains(AttributeName)) {
    // 		CachedAttributeValues.Add(AttributeName, AttributeSet.GetAttribute(AttributeName).GetCurrentValue());
    // 	}
    // 	return CachedAttributeValues[AttributeName];
    // }
}