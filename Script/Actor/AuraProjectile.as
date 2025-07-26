/**
 * @class AAuraProjectile
 * @brief 继承自 AActor，代表游戏中的投射物 Actor。
 * 该类处理投射物的移动、碰撞检测、音效播放以及造成伤害等逻辑。
 */
class AAuraProjectile : AActor
{
    // -------------------- Properties --------------------
    /**
     * @brief 指示该 Actor 是否需要在网络上进行复制，默认为 true 表示需要复制。
     */
    default bReplicates = true;

    /**
     * @brief 默认组件，作为该 Actor 的根组件，用于管理其他组件的位置和变换。
     */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于检测投射物与其他物体的碰撞。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    USphereComponent Sphere;
    // 设置球体组件的碰撞检测模式为仅查询
    default Sphere.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    // 设置球体组件的碰撞对象类型为投射物
    default Sphere.SetCollisionObjectType(AuraEnum::ECC_Projectile);
    // 设置球体组件对所有碰撞通道的响应为忽略
    default Sphere.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
    // 设置球体组件对动态世界碰撞通道的响应为重叠
    default Sphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
    // 设置球体组件对静态世界碰撞通道的响应为重叠
    default Sphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Overlap);
    // 设置球体组件对角色碰撞通道的响应为重叠
    default Sphere.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);

    /**
     * @brief 默认组件，用于控制投射物的移动。
     */
    UPROPERTY(DefaultComponent)
    UProjectileMovementComponent ProjectileMovement;
    // 设置投射物的初始速度为游戏常量定义的最大速度
    default ProjectileMovement.InitialSpeed = AuraConst::ProjectileMaxSpeed;
    // 设置投射物的最大速度为游戏常量定义的最大速度
    default ProjectileMovement.MaxSpeed = AuraConst::ProjectileMaxSpeed;
    // 设置投射物的重力影响比例为 0，即不受重力影响
    default ProjectileMovement.ProjectileGravityScale = 0;

    /**
     * @brief 投射物碰撞时播放的 Niagara 特效。
     */
    UPROPERTY(Category = Aura)
    UNiagaraSystem ImpactEffect;

    /**
     * @brief 投射物碰撞时播放的音效。
     */
    UPROPERTY(Category = Aura)
    USoundBase ImpactSound;

    /**
     * @brief 投射物飞行时循环播放的音效。
     */
    UPROPERTY(Category = Aura)
    USoundBase LoopingSound;

    /**
     * @brief 用于播放循环音效的音频组件。
     */
    UPROPERTY(Category = Aura)
    UAudioComponent LoopingSoundComponent;

    // -------------------- Varibles --------------------
    /**
     * @brief 伤害游戏玩法效果的规范句柄，用于在碰撞时对目标应用伤害效果。
     */
    FGameplayEffectSpecHandle DamageEffectSpecHandle;

    // -------------------- Functions --------------------
    /**
     * @brief 蓝图可重写的函数，当该 Actor 结束游戏时触发。
     * 若循环音效组件存在，则停止播放循环音效。
     * @param EndPlayReason 结束游戏的原因。
     */
    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
        // 若循环音效组件不为空，则停止播放音效
        if (LoopingSoundComponent != nullptr)
        {
            LoopingSoundComponent.Stop();
        }
    }

    /**
     * @brief 蓝图可重写的函数，当该 Actor 开始游戏时触发。
     * 生成并播放循环音效，同时设置投射物的生命周期。
     */
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // 在根组件上生成并播放循环音效
        LoopingSoundComponent = Gameplay::SpawnSoundAttached(LoopingSound, GetRootComponent());
        // 检查循环音效组件是否成功生成
        check(LoopingSoundComponent != nullptr);
        // 设置投射物的生命周期，超时后自动销毁
        SetLifeSpan(AuraConst::ProjectileLifeSpan);
    }

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 开始重叠时触发。
     * 播放碰撞音效和特效，若伤害效果句柄有效，则对目标应用伤害效果，最后销毁自身。
     * @param OtherActor 与之重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        // 打印与当前投射物重叠的其他 Actor 的名称，当前代码被注释
        // Print("Overlapping with: " + OtherActor.Name);
        // 在投射物当前位置播放碰撞音效
        Gameplay::PlaySoundAtLocation(ImpactSound, GetActorLocation(), GetActorRotation());
        // 在投射物当前位置播放 Niagara 碰撞特效
        Niagara::SpawnSystemAtLocation(ImpactEffect, GetActorLocation(), GetActorRotation());

        // 检查伤害效果句柄是否有效
        if (DamageEffectSpecHandle.IsValid())
        {
            // 获取重叠 Actor 的能力系统组件
            UAbilitySystemComponent TargetASC = AbilitySystem::GetAbilitySystemComponent(OtherActor);
            // 若目标的能力系统组件存在，则对其应用伤害效果
            if (TargetASC != nullptr)
            {
                TargetASC.ApplyGameplayEffectSpecToSelf(DamageEffectSpecHandle);
            }
        }

        // 销毁当前投射物 Actor
        DestroyActor();
    }
}
