/*
Features:
1. Have a static mesh component that is the mesh of the actor
2. Have a sphere component that is the collision size of the actor
3. Have a non-infinite gameplay effect that is applied to the actor when it overlaps with another actor
4. Destroy self when the gameplay effect is applied (overlapping with another actor)
*/

/**
 * @class AAuroEffectActor
 * @brief 继承自 AActor，代表游戏中的特效 Actor。
 * 该 Actor 包含静态网格组件和球体碰撞组件，当与其他 Actor 重叠时，
 * 会对重叠的 Actor 应用非永久的游戏玩法效果，随后销毁自身。
 */
class AAuroEffectActor : AActor
{
    /**
     * @brief 默认组件，作为该 Actor 的根组件，用于管理其他组件的位置和变换。
     */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于显示该 Actor 的静态网格模型。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UStaticMeshComponent Mesh;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于检测与其他 Actor 的重叠事件，决定碰撞范围。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    USphereComponent Sphere;

    /**
     * @brief 游戏玩法效果的类，当与其他 Actor 重叠时，会应用该类对应的游戏玩法效果。
     */
    UPROPERTY()
    TSubclassOf<UGameplayEffect> GameplayEffectClass;

    /**
     * @brief 该 Actor 的等级，用于确定应用的游戏玩法效果的等级，默认值为 1。
     */
    UPROPERTY()
    float32 ActorLevel = 1;

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 开始重叠时触发。
     * 打印重叠信息，对重叠的 Actor 应用游戏玩法效果，然后销毁自身。
     * @param OtherActor 与之重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        // 打印与当前 Actor 重叠的其他 Actor 的名称
        Print("Overlapping with: " + OtherActor.Name);
        // 以下代码为注释掉的示例，用于处理特定类型的角色并修改其属性
        // auto AngelscriptGASCharacter = Cast<AAngelscriptGASCharacter>(OtherActor);
        // if (AngelscriptGASCharacter != nullptr)
        // {
        // 	const UAttributeSet AttributeSet = AngelscriptGASCharacter.AbilitySystem.GetAttributeSet(UAuraAttributeSet.Get());
        // 	UAuraAttributeSet AuraAttributeSet = Cast<UAuraAttributeSet>(AttributeSet);
        // 	AuraAttributeSet.Health.SetCurrentValue(AuraAttributeSet.Health.GetCurrentValue() + 10);
        // 	DestroyActor();
        // }

        // 对当前 Actor 和重叠的 Actor 应用游戏玩法效果，使用当前 Actor 的等级
        GasUtil::ApplyGameplayEffect(this, OtherActor, GameplayEffectClass, ActorLevel);
        // 应用效果后销毁当前 Actor
        DestroyActor();
    }

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 结束重叠时触发。
     * 当前函数体为空，可取消注释打印信息来跟踪结束重叠事件。
     * @param OtherActor 结束重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        // 打印不再与当前 Actor 重叠的其他 Actor 的名称，当前代码被注释
        // Print("No longer overlapping with: " + OtherActor.Name);
    }
}