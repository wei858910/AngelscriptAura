namespace GasUtil
{
    FGameplayEffectSpecHandle MakeGameplayEffectSpecHandle(AActor SourceActor, TSubclassOf<UGameplayEffect> GameplayEffectClass, float32 Level = 1)
    {
        check(GameplayEffectClass != nullptr);
        UAbilitySystemComponent SourceASC = AbilitySystem::GetAbilitySystemComponent(SourceActor);
        if (SourceASC == nullptr)
        {
            return FGameplayEffectSpecHandle();
        }
        FGameplayEffectContextHandle EffectContextHandle = SourceASC.MakeEffectContext();
        EffectContextHandle.AddSourceObject(SourceActor);
        return SourceASC.MakeOutgoingSpec(GameplayEffectClass, Level, EffectContextHandle);
    }

    // TODO: 搞清楚为什么这里面调用 MakeGameplayEffectSpecHandle 生成 SpecHandle 后，整个 GE 就不生效了
    /**
     * @brief 将游戏玩法效果应用到目标 Actor 上。
     * 
     * 此函数会尝试获取目标 Actor 的能力系统组件，若存在则创建游戏玩法效果规范句柄，
     * 并将该效果应用到目标 Actor 自身。
     * 
     * @param SourceActor 效果的来源 Actor。
     * @param TargetActor 要应用效果的目标 Actor。
     * @param GameplayEffectClass 要应用的游戏玩法效果类。
     * @param Level 游戏玩法效果的等级，默认为 1。
     * @return FActiveGameplayEffectHandle 激活的游戏玩法效果句柄，若无法应用则返回空句柄。
     */
    FActiveGameplayEffectHandle ApplyGameplayEffect(AActor SourceActor, AActor TargetActor, TSubclassOf<UGameplayEffect> GameplayEffectClass, float32 Level = 1)
    {
        // 获取目标 Actor 的能力系统组件
        UAbilitySystemComponent TargetASC = AbilitySystem::GetAbilitySystemComponent(TargetActor);
        // 若目标 Actor 没有能力系统组件，则返回空的游戏玩法效果句柄
        if (TargetASC == nullptr)
        {
            return FActiveGameplayEffectHandle();
        }

        // 创建游戏玩法效果上下文句柄
        FGameplayEffectContextHandle EffectContextHandle = TargetASC.MakeEffectContext();
        // 将来源 Actor 添加到效果上下文句柄中
        EffectContextHandle.AddSourceObject(SourceActor);
        // 创建传出的游戏玩法效果规范句柄
        FGameplayEffectSpecHandle EffectSpecHandle = TargetASC.MakeOutgoingSpec(GameplayEffectClass, Level, EffectContextHandle);
        // 将游戏玩法效果规范应用到目标 Actor 自身，并返回激活的游戏玩法效果句柄
        return TargetASC.ApplyGameplayEffectSpecToSelf(EffectSpecHandle);
    }

    bool RemoveGameplayEffect(AActor TargetActor, FActiveGameplayEffectHandle EffectHandle, int StacksToRemove = -1)
    {
        UAbilitySystemComponent TargetASC = AbilitySystem::GetAbilitySystemComponent(TargetActor);
        if (TargetASC == nullptr)
        {
            return false;
        }
        return TargetASC.RemoveActiveGameplayEffect(EffectHandle, StacksToRemove);
    }

    FGameplayAbilitySpecHandle GiveAbility(AActor TargetActor, TSubclassOf<UGameplayAbility> AbilityClass, int Level = 1, int InputID = AuraConst::DefaultAbilityInputID, UObject SourceObject = nullptr)
    {
        UAbilitySystemComponent TargetASC = AbilitySystem::GetAbilitySystemComponent(TargetActor);
        if (TargetASC == nullptr || !TargetActor.HasAuthority())
        {
            return FGameplayAbilitySpecHandle();
        }

        FGameplayAbilitySpec AbilitySpec = FGameplayAbilitySpec(AbilityClass, Level, InputID, SourceObject);
        return TargetASC.GiveAbility(AbilitySpec);
    }

    FGameplayAbilitySpec MakeAbilitySpec(TSubclassOf<UGameplayAbility> AbilityClass, int Level = 1)
    {
        FGameplayAbilitySpec AbilitySpec = FGameplayAbilitySpec(AbilityClass, Level);
        return AbilitySpec;
    }

    AAuraCharacterBase GetAvatarCharacterFromASC(UAngelscriptAbilitySystemComponent ASC)
    {
        AActor AvatarActor = ASC.AbilityActorInfo.GetAvatarActor();
        if (AvatarActor == nullptr)
        {
            return nullptr;
        }
        return Cast<AAuraCharacterBase>(AvatarActor);
    }

    AAuraCharacterBase GetAvatarCharacterFromAbility(UGameplayAbility Ability)
    {
        AActor AvatarActor = Ability.GetAvatarActorFromActorInfo();
        if (AvatarActor == nullptr)
        {
            return nullptr;
        }
        return Cast<AAuraCharacterBase>(AvatarActor);
    }
} // namespace GasUtil