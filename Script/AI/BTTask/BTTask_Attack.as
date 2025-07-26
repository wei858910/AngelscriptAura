/**
 * @class UBTTask_Attack
 * @brief 继承自 UBTTask_BlueprintBase，代表行为树中的攻击任务节点。
 * 该任务用于控制 AI 角色执行攻击动作，通过能力系统激活攻击能力。
 */
class UBTTask_Attack : UBTTask_BlueprintBase
{
    /**
     * @brief 行为树节点的名称，默认为 "Attack"，用于在行为树编辑器中标识该节点。
     */
    default NodeName = "Attack";

    /**
     * @brief 蓝图可重写的函数，AI 控制器执行此任务时调用。
     * 调用 ExectueImpl 函数执行实际的攻击逻辑，并根据其返回结果结束任务执行。
     * @param OwnerController 执行此任务的 AI 控制器。
     * @param ControlledPawn AI 控制器控制的 pawn 对象。
     */
    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        // 调用 ExectueImpl 函数执行攻击逻辑，并根据返回结果结束任务执行
        FinishExecute(ExectueImpl(OwnerController, ControlledPawn));
    }

    /**
     * @brief 执行实际攻击逻辑的函数。
     * 尝试获取受控 pawn 的能力系统组件，若存在则激活带有攻击标签的能力。
     * @param OwnerController 执行此任务的 AI 控制器。
     * @param ControlledPawn AI 控制器控制的 pawn 对象。
     * @return 若成功激活攻击能力返回 true，否则返回 false。
     */
    bool ExectueImpl(AAIController OwnerController, APawn ControlledPawn)
    {
        // 获取受控 pawn 的能力系统组件
        UAbilitySystemComponent ASC = AbilitySystem::GetAbilitySystemComponent(ControlledPawn);
        // 若能力系统组件为空，说明无法执行攻击，返回 false
        if (ASC == nullptr)
        {
            return false;
        }

        // 创建一个游戏玩法标签容器
        FGameplayTagContainer TagContainer;
        // 向标签容器中添加攻击能力的标签
        TagContainer.AddTag(GameplayTags::Abilities_Attack);
        // 尝试通过标签激活攻击能力，并返回激活结果
        return ASC.TryActivateAbilitiesByTag(TagContainer);
    }

    /**
     * @brief 选择器函数（当前注释掉）。
     * 遍历节点数组，只要有一个节点成功则返回 true，否则返回 false。
     * @return 若有节点成功返回 true，否则返回 false。
     */
    // bool Selector() {
    // 	// 定义一个整数节点数组
    // 	TArray<int> Nodes;
    // 	// 遍历节点数组
    // 	for (int node : Nodes) {
    // 		// 若节点执行成功，返回 true
    // 		if (node.IsSucceed()) {
    // 			return true;
    // 		}
    // 	}
    // 	// 所有节点都未成功，返回 false
    // 	return false;
    // }

    /**
     * @brief 序列器函数（当前注释掉）。
     * 遍历节点数组，只要有一个节点失败则返回 false，全部成功则返回 true。
     * @return 若所有节点都成功返回 true，否则返回 false。
     */
    // bool Sequence() {
    // 	// 定义一个整数节点数组
    // 	TArray<int> Nodes;
    // 	// 遍历节点数组
    // 	for (int node : Nodes) {
    // 		// 若节点执行失败，返回 false
    // 		if (!node.IsSucceed()) {
    // 			return false;
    // 		}
    // 	}
    // 	// 所有节点都成功，返回 true
    // 	return true;
    // }
}
