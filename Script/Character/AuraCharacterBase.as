
class AAuraCharacterBase : AAngelscriptGASCharacter
{
    // -------------------- Const --------------------
    const float32 DISSOLVE_TIME = 2;
    const float32 RAGDOLL_TIME = 1.5;

    // -------------------- Properties --------------------
    default bReplicates = true;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

    // Do not set collision on mesh, keep default collision. (Only use CapsuleComponent for collision)
    // default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

    UPROPERTY(DefaultComponent, BlueprintReadOnly, Category = "Combat", Attach = "CharacterMesh0", AttachSocket = "WeaponHandSocket")
    USkeletalMeshComponent Weapon;
    default Weapon.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    UPROPERTY(DefaultComponent)
    UMotionWarpingComponent MotionWarping;

    UPROPERTY(Category = Aura)
    uint16 CharacterID;

    UPROPERTY(Category = Aura)
    TSubclassOf<UWidgetComponent> DamageComponentClass;

    // -------------------- Varibles --------------------
    UGasModule GasModule;
    AActor     AttackTarget;

    // -------------------- Functions --------------------
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        check(CharacterID != 0);
        auto CharacterMap = AuraUtil::GetSDataMgr().CharacterMap;
        check(CharacterMap.Contains(CharacterID));

        GasModule = Cast<UGasModule>(NewObject(this, UGasModule, n"UGasModule"));
        GasModule.Init(this);

        // Startup Gameplay Abilities
        FSDataCharacter SDataCharacter = CharacterMap[CharacterID];
        for (auto StartupAbilityClass : SDataCharacter.StartupAbilities)
        {
            FGameplayAbilitySpecHandle Handle = GasUtil::GiveAbility(this, StartupAbilityClass);
        }

        // Startup Gameplay Effects
        ECharacterClass      CharacterClass = SDataCharacter.CharacterClass;
        FSDataCharacterClass SDataCharacterClass = AuraUtil::GetSDataMgr().CharacterClassMap[CharacterClass];
        for (auto EffectClass : SDataCharacterClass.AttributeEffects)
        {
            GasUtil::ApplyGameplayEffect(this, this, EffectClass);
        }

        // 玩家和怪物都有的一些 Ability // TODO: 移到 GlobalConfig 里去
        GasUtil::GiveAbility(this, UAGA_HitReact);
    }

    void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData)
    { // virtual empty
    }

    UAnimMontage GetHitReactMontage()
    {
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        return SDataCharacter.HitReactMontage;
        // if (IsDead()) {
        // 	return SDataCharacter.DeathMontage;
        // } else {
        // 	return SDataCharacter.HitReactMontage;
        // }
    }

    void BeHit(float32 Damage, EDamageType DamageType)
    {
        if (DamageType == EDamageType::Miss)
        {
            ShowFloatText(FText::FromString("Miss"), FLinearColor::Gray);
            return;
        }

        if (Damage <= 0)
        {
            return;
        }

        // 飘字
        FLinearColor DamageColor = FLinearColor::White;
        if (DamageType == EDamageType::Critical)
        {
            DamageColor = FLinearColor::Red;
        }
        else if (DamageType == EDamageType::Lucky)
        {
            DamageColor = FLinearColor::Green;
        }
        ShowFloatText(FText::AsNumber(Damage, FNumberFormattingOptions()), DamageColor);

        // 受击动画
        TryPlayHitReactMontage();
        // 受击特效
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        if (SDataCharacter.ImpactEffect != nullptr)
        {
            Niagara::SpawnSystemAtLocation(SDataCharacter.ImpactEffect, GetActorLocation(), GetActorRotation());
        }
    }

    bool TryPlayHitReactMontage()
    {
        FGameplayAbilitySpec OutSpec;
        if (AbilitySystem.FindAbilitySpecFromClass(UAGA_HitReact, OutSpec))
        {
            if (!OutSpec.IsActive())
            {
                return AbilitySystem.TryActivateAbility(OutSpec.Handle);
            }
        }
        return false;
    }

    bool IsDead()
    {
        return GasModule.GetAttributeValue(AuraAttributes::Health) <= 0;
    }

    void Die()
    {
        // Ragdoll Die
        Weapon.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, true);
        AuraUtil::RagdollComponent(Weapon);
        AuraUtil::RagdollComponent(Mesh);
        CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

        // LifeSpan
        SetLifeSpan(RAGDOLL_TIME + DISSOLVE_TIME);

        System::SetTimer(this, n"Dissolve", RAGDOLL_TIME, false);
    }

    UFUNCTION()
    private void Dissolve()
    {
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        if (System::IsValid(SDataCharacter.DissolveMaterial))
        {
            UMaterialInstanceDynamic MID_Dissolve = Material::CreateDynamicMaterialInstance(SDataCharacter.DissolveMaterial);
            Mesh.SetMaterial(0, MID_Dissolve);

            AuraUtil::GameInstance().TickerMgr.CreateTicker(DISSOLVE_TIME, FTickerDelegate(this, n"DissolveTick"), ETickerFuncType::BodyDissolve);
        }
        if (System::IsValid(SDataCharacter.WeaponDissolveMaterial))
        {
            UMaterialInstanceDynamic MID_WeaponDissolve = Material::CreateDynamicMaterialInstance(SDataCharacter.WeaponDissolveMaterial);
            Weapon.SetMaterial(0, MID_WeaponDissolve);

            AuraUtil::GameInstance().TickerMgr.CreateTicker(DISSOLVE_TIME, FTickerDelegate(this, n"DissolveTick"), ETickerFuncType::WeaponDissolve);
        }
    }

    UFUNCTION()
    private void DissolveTick(float DeltaTime, float Percent, ETickerFuncType FuncType, TArray<UObject> Params)
    {
        if (FuncType == ETickerFuncType::BodyDissolve)
        {
            Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", Percent);
        }
        else if (FuncType == ETickerFuncType::WeaponDissolve)
        {
            Weapon.SetScalarParameterValueOnMaterials(n"Dissolve", Percent);
        }
    }

    void ShowFloatText(FText Text, FLinearColor Color = FLinearColor::White)
    {
        UWidgetComponent FloatTextComponent = this.CreateComponent(DamageComponentClass);
        UAUW_FloatText   AUW_FloatText = Cast<UAUW_FloatText>(FloatTextComponent.GetWidget());
        if (AUW_FloatText == nullptr)
        {
            return;
        }

        AUW_FloatText.Ctor(this);
        AUW_FloatText.OwnerWidgetComponent = FloatTextComponent;
        AUW_FloatText.Text_FloatText.SetText(Text);
        AUW_FloatText.Text_FloatText.SetColorAndOpacity(Color);

        FloatTextComponent.AttachToComponent(GetRootComponent(), NAME_None, EAttachmentRule::KeepRelative);
        FloatTextComponent.DetachFromComponent(EDetachmentRule::KeepWorld);
    }

    bool CanRangeAttack()
    {
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        return SDataCharacter.CharacterClass != ECharacterClass::Warrior;
    }

    void SetFacingTarget(const FVector& TargetLocation)
    {
        MotionWarping.AddOrUpdateWarpTargetFromLocation(n"FacingTarget", TargetLocation);
    }

    FVector GetSocketLocationByGameplayTag(FGameplayTag GameplayTag)
    {
        if (GameplayTag == GameplayTags::Montage_Attack_Weapon)
        {
            return Weapon.GetSocketLocation(AuraConst::SocketName_WeaponTip);
        }
        else if (GameplayTag == GameplayTags::Montage_Attack_LeftHand)
        {
            return Mesh.GetSocketLocation(AuraConst::SocketName_LeftHand);
        }
        else if (GameplayTag == GameplayTags::Montage_Attack_RightHand)
        {
            return Mesh.GetSocketLocation(AuraConst::SocketName_RightHand);
        }
        return FVector::ZeroVector;
    }
}
