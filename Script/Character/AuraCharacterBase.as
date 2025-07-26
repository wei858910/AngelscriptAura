/**
 * @class AAuraCharacterBase
 * @brief 继承自 AAngelscriptGASCharacter，是游戏中角色的基础类。
 * 该类包含角色的常量定义、属性设置、变量声明以及一系列功能函数，
 * 用于处理角色的初始化、受击、死亡、溶解等逻辑。
 */
class AAuraCharacterBase : AAngelscriptGASCharacter
{
    // -------------------- Const --------------------
    /**
     * @brief 角色死亡后溶解效果的持续时间，单位为秒。
     */
    const float32 DISSOLVE_TIME = 2;
    /**
     * @brief 角色死亡后进入布娃娃状态的持续时间，单位为秒。
     */
    const float32 RAGDOLL_TIME = 1.5;

    // -------------------- Properties --------------------
    /**
     * @brief 指示该角色是否需要在网络上进行复制，默认为 true。
     */
    default bReplicates = true;
    /**
     * @brief 默认设置角色骨骼网格组件的碰撞为禁用状态。
     */
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    /**
     * @brief 默认设置角色胶囊体组件对相机碰撞通道的响应为忽略。
     */
    default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

    // Do not set collision on mesh, keep default collision. (Only use CapsuleComponent for collision)
    // default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);

    /**
     * @brief 默认组件，角色的武器骨骼网格组件。
     * 该组件只读，属于战斗类别，附加到 CharacterMesh0 的 WeaponHandSocket 插槽。
     */
    UPROPERTY(DefaultComponent, BlueprintReadOnly, Category = "Combat", Attach = "CharacterMesh0", AttachSocket = "WeaponHandSocket")
    USkeletalMeshComponent Weapon;
    /**
     * @brief 默认设置武器组件的碰撞为禁用状态。
     */
    default Weapon.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    /**
     * @brief 默认组件，运动扭曲组件，用于处理角色的运动扭曲效果。
     */
    UPROPERTY(DefaultComponent)
    UMotionWarpingComponent MotionWarping;

    /**
     * @brief 角色的唯一标识符，属于 Aura 类别。
     */
    UPROPERTY(Category = Aura)
    uint16 CharacterID;

    /**
     * @brief 伤害显示组件的类，属于 Aura 类别。
     */
    UPROPERTY(Category = Aura)
    TSubclassOf<UWidgetComponent> DamageComponentClass;

    // -------------------- Varibles --------------------
    /**
     * @brief GAS模块，用于处理角色的能力系统相关逻辑。
     */
    UGasModule GasModule;
    /**
     * @brief 角色的攻击目标。
     */
    AActor     AttackTarget;

    // -------------------- Functions --------------------
    /**
     * @brief 蓝图可重写的函数，在角色开始游戏时调用。
     * 检查角色 ID 的有效性，初始化气体模块，赋予角色初始游戏玩法能力和效果。
     */
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // 检查角色 ID 是否不为 0，若为 0 则触发断言
        check(CharacterID != 0);
        // 获取角色数据映射表
        auto CharacterMap = AuraUtil::GetSDataMgr().CharacterMap;
        // 检查角色数据映射表中是否包含当前角色 ID，若不包含则触发断言
        check(CharacterMap.Contains(CharacterID));

        // 创建气体模块实例并初始化
        GasModule = Cast<UGasModule>(NewObject(this, UGasModule, n"UGasModule"));
        GasModule.Init(this);

        // Startup Gameplay Abilities
        // 获取当前角色的数据
        FSDataCharacter SDataCharacter = CharacterMap[CharacterID];
        // 遍历角色初始能力列表，赋予角色相应的游戏玩法能力
        for (auto StartupAbilityClass : SDataCharacter.StartupAbilities)
        {
            FGameplayAbilitySpecHandle Handle = GasUtil::GiveAbility(this, StartupAbilityClass);
        }

        // Startup Gameplay Effects
        // 获取角色的职业类型
        ECharacterClass      CharacterClass = SDataCharacter.CharacterClass;
        // 获取角色职业类型的数据
        FSDataCharacterClass SDataCharacterClass = AuraUtil::GetSDataMgr().CharacterClassMap[CharacterClass];
        // 遍历角色职业类型的属性效果列表，应用相应的游戏玩法效果
        for (auto EffectClass : SDataCharacterClass.AttributeEffects)
        {
            GasUtil::ApplyGameplayEffect(this, this, EffectClass);
        }

        // 玩家和怪物都有的一些 Ability // TODO: 移到 GlobalConfig 里去
        // 赋予角色受击反应能力
        GasUtil::GiveAbility(this, UAGA_HitReact);
    }

    /**
     * @brief 当角色属性发生变化时调用的函数，当前为空函数。
     * @param AttributeChangeData 包含属性变化数据的结构体。
     */
    void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData)
    { // virtual empty
    }

    /**
     * @brief 获取角色受击反应动画蒙太奇。
     * @return 角色的受击反应动画蒙太奇。
     */
    UAnimMontage GetHitReactMontage()
    {
        // 获取当前角色的数据
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        return SDataCharacter.HitReactMontage;
        // if (IsDead()) {
        // 	return SDataCharacter.DeathMontage;
        // } else {
        // 	return SDataCharacter.HitReactMontage;
        // }
    }

    /**
     * @brief 处理角色受击逻辑。
     * 根据伤害类型显示不同颜色的飘字，播放受击动画和特效。
     * @param Damage 受到的伤害值。
     * @param DamageType 伤害类型。
     */
    void BeHit(float32 Damage, EDamageType DamageType)
    {
        // 若伤害类型为未命中，显示灰色的 "Miss" 飘字并返回
        if (DamageType == EDamageType::Miss)
        {
            ShowFloatText(FText::FromString("Miss"), FLinearColor::Gray);
            return;
        }

        // 若伤害值小于等于 0，不做处理直接返回
        if (Damage <= 0)
        {
            return;
        }

        // 飘字
        // 初始化伤害飘字颜色为白色
        FLinearColor DamageColor = FLinearColor::White;
        // 若伤害类型为暴击，设置颜色为红色
        if (DamageType == EDamageType::Critical)
        {
            DamageColor = FLinearColor::Red;
        }
        // 若伤害类型为幸运一击，设置颜色为绿色
        else if (DamageType == EDamageType::Lucky)
        {
            DamageColor = FLinearColor::Green;
        }
        // 显示带有伤害值和对应颜色的飘字
        ShowFloatText(FText::AsNumber(Damage, FNumberFormattingOptions()), DamageColor);

        // 受击动画
        // 尝试播放受击反应动画蒙太奇
        TryPlayHitReactMontage();
        // 受击特效
        // 获取当前角色的数据
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        // 若角色的受击特效不为空，在角色位置播放特效
        if (SDataCharacter.ImpactEffect != nullptr)
        {
            Niagara::SpawnSystemAtLocation(SDataCharacter.ImpactEffect, GetActorLocation(), GetActorRotation());
        }
    }

    /**
     * @brief 尝试播放角色的受击反应动画蒙太奇。
     * @return 若成功激活受击反应能力返回 true，否则返回 false。
     */
    bool TryPlayHitReactMontage()
    {
        // 用于存储找到的能力规范
        FGameplayAbilitySpec OutSpec;
        // 尝试从能力系统中找到受击反应能力的规范
        if (AbilitySystem.FindAbilitySpecFromClass(UAGA_HitReact, OutSpec))
        {
            // 若该能力未激活，尝试激活该能力
            if (!OutSpec.IsActive())
            {
                return AbilitySystem.TryActivateAbility(OutSpec.Handle);
            }
        }
        return false;
    }

    /**
     * @brief 判断角色是否已死亡。
     * @return 若角色生命值小于等于 0 返回 true，否则返回 false。
     */
    bool IsDead()
    {
        return GasModule.GetAttributeValue(AuraAttributes::Health) <= 0;
    }

    /**
     * @brief 处理角色死亡逻辑。
     * 使武器和角色进入布娃娃状态，禁用胶囊体组件碰撞，设置角色生命周期并启动溶解计时器。
     */
    void Die()
    {
        // Ragdoll Die
        // 将武器从组件上分离，保持世界坐标
        Weapon.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, true);
        // 使武器进入布娃娃状态
        AuraUtil::RagdollComponent(Weapon);
        // 使角色骨骼网格组件进入布娃娃状态
        AuraUtil::RagdollComponent(Mesh);
        // 禁用胶囊体组件的碰撞
        CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

        // LifeSpan
        // 设置角色的生命周期为布娃娃时间加上溶解时间
        SetLifeSpan(RAGDOLL_TIME + DISSOLVE_TIME);

        // 在布娃娃时间后调用 Dissolve 函数
        System::SetTimer(this, n"Dissolve", RAGDOLL_TIME, false);
    }

    /**
     * @brief 处理角色溶解逻辑。
     * 创建动态材质实例并应用到角色和武器上，启动溶解计时器。
     */
    UFUNCTION()
    private void Dissolve()
    {
        // 获取当前角色的数据
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        // 若角色的溶解材质有效，创建动态材质实例并应用到角色骨骼网格组件上，启动溶解计时器
        if (System::IsValid(SDataCharacter.DissolveMaterial))
        {
            UMaterialInstanceDynamic MID_Dissolve = Material::CreateDynamicMaterialInstance(SDataCharacter.DissolveMaterial);
            Mesh.SetMaterial(0, MID_Dissolve);

            AuraUtil::GameInstance().TickerMgr.CreateTicker(DISSOLVE_TIME, FTickerDelegate(this, n"DissolveTick"), ETickerFuncType::BodyDissolve);
        }
        // 若角色的武器溶解材质有效，创建动态材质实例并应用到武器组件上，启动溶解计时器
        if (System::IsValid(SDataCharacter.WeaponDissolveMaterial))
        {
            UMaterialInstanceDynamic MID_WeaponDissolve = Material::CreateDynamicMaterialInstance(SDataCharacter.WeaponDissolveMaterial);
            Weapon.SetMaterial(0, MID_WeaponDissolve);

            AuraUtil::GameInstance().TickerMgr.CreateTicker(DISSOLVE_TIME, FTickerDelegate(this, n"DissolveTick"), ETickerFuncType::WeaponDissolve);
        }
    }

    /**
     * @brief 处理角色溶解过程中的更新逻辑。
     * 根据溶解类型更新角色或武器的溶解参数。
     * @param DeltaTime 从上一帧到当前帧的时间间隔。
     * @param Percent 溶解进度百分比。
     * @param FuncType 溶解类型。
     * @param Params 附加参数数组。
     */
    UFUNCTION()
    private void DissolveTick(float DeltaTime, float Percent, ETickerFuncType FuncType, TArray<UObject> Params)
    {
        // 若溶解类型为角色身体溶解，更新角色骨骼网格组件的溶解参数
        if (FuncType == ETickerFuncType::BodyDissolve)
        {
            Mesh.SetScalarParameterValueOnMaterials(n"Dissolve", Percent);
        }
        // 若溶解类型为武器溶解，更新武器组件的溶解参数
        else if (FuncType == ETickerFuncType::WeaponDissolve)
        {
            Weapon.SetScalarParameterValueOnMaterials(n"Dissolve", Percent);
        }
    }

    /**
     * @brief 显示伤害飘字。
     * 创建伤害显示组件，设置飘字文本和颜色，并将其附加到角色根组件上。
     * @param Text 飘字显示的文本。
     * @param Color 飘字的颜色，默认为白色。
     */
    void ShowFloatText(FText Text, FLinearColor Color = FLinearColor::White)
    {
        // 创建伤害显示组件实例
        UWidgetComponent FloatTextComponent = this.CreateComponent(DamageComponentClass);
        // 将伤害显示组件的小部件转换为 UAUW_FloatText 类型
        UAUW_FloatText   AUW_FloatText = Cast<UAUW_FloatText>(FloatTextComponent.GetWidget());
        // 若转换失败，直接返回
        if (AUW_FloatText == nullptr)
        {
            return;
        }

        // 初始化 UAUW_FloatText 组件
        AUW_FloatText.Ctor(this);
        AUW_FloatText.OwnerWidgetComponent = FloatTextComponent;
        // 设置飘字文本
        AUW_FloatText.Text_FloatText.SetText(Text);
        // 设置飘字颜色
        AUW_FloatText.Text_FloatText.SetColorAndOpacity(Color);

        // 将伤害显示组件附加到角色根组件上
        FloatTextComponent.AttachToComponent(GetRootComponent(), NAME_None, EAttachmentRule::KeepRelative);
        // 将伤害显示组件从父组件分离，保持世界坐标
        FloatTextComponent.DetachFromComponent(EDetachmentRule::KeepWorld);
    }

    /**
     * @brief 判断角色是否可以进行远程攻击。
     * @return 若角色职业不是战士则返回 true，否则返回 false。
     */
    bool CanRangeAttack()
    {
        // 获取当前角色的数据
        FSDataCharacter SDataCharacter = AuraUtil::GetSDataMgr().CharacterMap[CharacterID];
        return SDataCharacter.CharacterClass != ECharacterClass::Warrior;
    }

    /**
     * @brief 设置角色面向目标的位置。
     * @param TargetLocation 目标位置。
     */
    void SetFacingTarget(const FVector& TargetLocation)
    {
        // 添加或更新运动扭曲目标位置
        MotionWarping.AddOrUpdateWarpTargetFromLocation(n"FacingTarget", TargetLocation);
    }

    /**
     * @brief 根据游戏玩法标签获取对应插槽的位置。
     * @param GameplayTag 游戏玩法标签。
     * @return 对应插槽的位置，若未找到则返回零向量。
     */
    FVector GetSocketLocationByGameplayTag(FGameplayTag GameplayTag)
    {
        // 若游戏玩法标签为攻击武器标签，返回武器尖端插槽的位置
        if (GameplayTag == GameplayTags::Montage_Attack_Weapon)
        {
            return Weapon.GetSocketLocation(AuraConst::SocketName_WeaponTip);
        }
        // 若游戏玩法标签为攻击左手标签，返回左手插槽的位置
        else if (GameplayTag == GameplayTags::Montage_Attack_LeftHand)
        {
            return Mesh.GetSocketLocation(AuraConst::SocketName_LeftHand);
        }
        // 若游戏玩法标签为攻击右手标签，返回右手插槽的位置
        else if (GameplayTag == GameplayTags::Montage_Attack_RightHand)
        {
            return Mesh.GetSocketLocation(AuraConst::SocketName_RightHand);
        }
        // 若未找到对应标签，返回零向量
        return FVector::ZeroVector;
    }
}
