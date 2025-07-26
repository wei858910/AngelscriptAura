/**
 * @class UAAN_MontageEvent
 * @brief 继承自 UAnimNotify，用于在动画播放期间触发游戏玩法事件。
 * 当动画通知被触发时，该类会向关联的 Actor 发送一个带有指定标签的游戏玩法事件。
 */
class UAAN_MontageEvent : UAnimNotify
{
    /**
     * @brief 游戏玩法事件标签，用于标识要发送的游戏玩法事件类型。
     * 该标签将在动画通知触发时被用于发送对应的游戏玩法事件。
     */
    UPROPERTY()
    FGameplayTag EventTag;

    /**
     * @brief 蓝图可重写的函数，当动画通知被触发时调用。
     * 此函数会向骨骼网格组件所属的 Actor 发送一个带有指定标签的游戏玩法事件。
     * @param MeshComp 触发动画通知的骨骼网格组件。
     * @param Animation 正在播放的动画序列，当前未使用该参数。
     * @param EventReference 动画通知事件的引用，当前未使用该参数。
     * @return 始终返回 true，表示动画通知处理成功。
     */
    UFUNCTION(BlueprintOverride)
    bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
    {
        // 向骨骼网格组件所属的 Actor 发送带有指定标签的游戏玩法事件
        AbilitySystem::SendGameplayEventToActor(MeshComp.GetOwner(), EventTag, FGameplayEventData());
        // 返回 true 表示动画通知处理成功
        return true;
    }
}
