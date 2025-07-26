/**
 * @class AAuraAIController
 * @brief 继承自 AAIController，代表游戏中的 AI 控制器类。
 * 该类用于控制 AI 角色的行为，通过行为树组件来管理 AI 的行为逻辑。
 */
class AAuraAIController : AAIController
{
    /**
     * @brief 默认组件，行为树组件，用于管理和执行 AI 的行为树逻辑。
     * 该组件会根据预设的行为树节点来控制 AI 角色的行动，如移动、攻击等。
     */
    UPROPERTY(DefaultComponent)
    UBehaviorTreeComponent BehaviorTreeComponent;
}
