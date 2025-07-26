/**
 * @class UEQC_Player
 * @brief 继承自 UEnvQueryContext_BlueprintBase，用于在环境查询（EQS）中提供玩家角色 Actor 集合。
 * 该类重写了 ProvideActorsSet 函数，从游戏世界中获取所有特定类型的 Actor 作为查询结果。
 */
class UEQC_Player : UEnvQueryContext_BlueprintBase
{
    /**
     * @brief 蓝图可重写的函数，用于在环境查询中提供符合条件的 Actor 集合。
     * 此函数会获取游戏世界中所有 AAuraCharacter 类型的 Actor 并添加到 ResultingActorsSet 中。
     * 
     * 注意：使用 Gameplay 命名空间里的同名函数在 PIE（Play In Editor）模式下执行时，
     * 会报没有 WorldContext 的错误，因此改用全局命名空间里的函数。
     * 
     * @param QuerierObject 发起查询的对象，当前未使用该参数。
     * @param QuerierActor 发起查询的 Actor，当前未使用该参数。
     * @param ResultingActorsSet 用于存储查询结果的 Actor 数组的引用。
     */
    UFUNCTION(BlueprintOverride)
    void ProvideActorsSet(UObject QuerierObject, AActor QuerierActor, TArray<AActor>& ResultingActorsSet) const
    {
        // 注释说明：在 PIE 模式下，Gameplay 命名空间里的同名函数执行时会报没有 WorldContext 的错误
        // 因此避免使用，改用全局命名空间里的函数
        // Gameplay::GetAllActorsWithTag(AuraConst::PlayerTag, ResultingActorsSet);
        // Gameplay::GetAllActorsOfClass(AAuraCharacter, ResultingActorsSet);
        // 调用全局命名空间里的函数，获取所有 AAuraCharacter 类型的 Actor 并存储到 ResultingActorsSet 中
        GetAllActorsOfClass(AAuraCharacter, ResultingActorsSet);
    }
}
