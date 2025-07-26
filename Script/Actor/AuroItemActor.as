/**
 * @class AAuroItemActor
 * @brief 继承自 AActor，代表游戏中的物品 Actor，用于处理物品的交互逻辑。
 * 当其他 Actor 与该物品重叠时，会应用游戏效果并触发物品拾取事件，随后销毁自身。
 */
class AAuroItemActor : AActor
{
    /**
     * @brief 默认组件，作为该 Actor 的根组件，用于管理其他组件的位置和变换。
     */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent SceneRoot;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于显示物品的静态网格模型。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    UStaticMeshComponent Mesh;

    /**
     * @brief 默认组件，附加到 SceneRoot 上，用于检测与其他 Actor 的重叠事件。
     */
    UPROPERTY(DefaultComponent, Attach = SceneRoot)
    USphereComponent Sphere;

    /**
     * @brief 物品的 ID，在数据表 DT_SData_Item 中进行配置，用于唯一标识物品。
     */
    UPROPERTY()
    EItemID ItemID;

    /**
     * @brief 该 Actor 的等级，用于确定应用的游戏玩法效果的等级，默认值为 1。
     */
    UPROPERTY()
    float32 ActorLevel = 1;

    /**
     * @brief 蓝图可重写的函数，当该 Actor 与其他 Actor 开始重叠时触发。
     * 若重叠的 Actor 带有敌人标签则不做处理，否则应用物品对应的游戏效果，
     * 触发物品拾取事件并销毁自身。
     * @param OtherActor 与之重叠的其他 Actor 实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        // 检查重叠的 Actor 是否带有敌人标签，若是则直接返回，不做处理
        if (OtherActor.ActorHasTag(AuraConst::EnemyTag))
        {
            return;
        }

        // 根据物品 ID 从数据表中获取物品数据
        FSDataItem Item = SDataUtil::GetItem(ItemID);
        // 对自身和重叠的 Actor 应用物品对应的游戏玩法效果，使用当前 Actor 的等级
        GasUtil::ApplyGameplayEffect(this, OtherActor, Item.GameplayEffectClass, ActorLevel);

        // 触发游戏实例中的物品拾取事件，广播物品 ID
        AuraUtil::GameInstance().EventMgr.OnItemPickedUpEvent.Broadcast(ItemID);

        // 销毁当前 Actor
        DestroyActor();
    }
}