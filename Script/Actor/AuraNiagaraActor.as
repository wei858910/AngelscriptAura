
/*
Features:
1. Have a box component that is the size of the actor
2. Have a Niagara component that is the size of the actor
3. Have a infinite gameplay effect that is applied to the actor when it overlaps with another actor
4. When another actor ends overlapping with the actor, the gameplay effect is removed
*/

/**
 * @class AAuraNiagaraActor
 * @brief 继承自 AActor，代表游戏中带有 Niagara 特效的 Actor。
 * 该 Actor 具备碰撞检测功能，当与其他 Actor 重叠时，会对其应用无限期的游戏玩法效果；
 * 当重叠结束时，移除该效果。
 */
class AAuraNiagaraActor : AActor
{
    /**
     * @brief 默认组件，作为该 Actor 的根组件，用于管理其他组件的位置和变换。
     */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于定义该 Actor 的碰撞体积，以盒子形状呈现。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UBoxComponent Box;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于播放 Niagara 特效，展示该 Actor 的视觉效果。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UNiagaraComponent Niagara;

    /**
     * @brief 游戏玩法效果的类，当与其他 Actor 重叠时，会应用该类对应的无限期游戏玩法效果。
     */
    UPROPERTY()
    TSubclassOf<UGameplayEffect> GameplayEffectClass;

    /**
     * @brief 活动游戏玩法效果的句柄，用于跟踪和管理应用到其他 Actor 上的游戏玩法效果。
     */
    FActiveGameplayEffectHandle EffectHandle;

    /**
     * @brief 蓝图可重写的函数，在该 Actor 开始游戏时触发。
     * 检查游戏玩法效果类是否有效，若无效则可能导致程序出错。
     */
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // 确保游戏玩法效果类不为空，避免后续应用效果时出错
        check(GameplayEffectClass != nullptr);
    }

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 开始重叠时触发。
     * 打印重叠信息，并对重叠的 Actor 应用游戏玩法效果，记录效果句柄。
     * @param OtherActor 与之重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        // 打印与当前 Actor 重叠的其他 Actor 的名称
        Print("Overlapping with: " + OtherActor.Name);
        // 对当前 Actor 和重叠的 Actor 应用游戏玩法效果，并获取效果句柄
        EffectHandle = GasUtil::ApplyGameplayEffect(this, OtherActor, GameplayEffectClass);
    }

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 结束重叠时触发。
     * 打印结束重叠信息，移除之前应用的游戏玩法效果，并重置效果句柄。
     * @param OtherActor 结束重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        // 打印不再与当前 Actor 重叠的其他 Actor 的名称
        Print("No longer overlapping with: " + OtherActor.Name);
        // 从重叠的 Actor 上移除之前应用的游戏玩法效果
        GasUtil::RemoveGameplayEffect(OtherActor, EffectHandle);
        // 将效果句柄重置为游戏常量定义的空句柄
        EffectHandle = AuraConst::EmptyEffectHandle;
    }
}
