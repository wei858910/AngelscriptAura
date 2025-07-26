/**
 * @class UBTTask_GoAroundTarget
 * @brief 继承自 UBTTask_BlueprintBase，代表行为树中的绕目标移动任务节点。
 * 该任务用于让 AI 角色在目标周围的可导航区域随机选择一个位置并记录到黑板中。
 */
class UBTTask_GoAroundTarget : UBTTask_BlueprintBase
{
    /**
     * @brief 黑板键选择器，用于指定存储绕目标移动相关位置信息的黑板键。
     * 该键允许存储向量类型的数据。
     */
    UPROPERTY()
    FBlackboardKeySelector AroundTarget;

    /**
     * @brief 向量类型的黑板键对象，初始化为空指针。
     * 用于指定 AroundTarget 允许的类型为向量类型。
     */
    private UBlackboardKeyType_Vector VectorObject = nullptr;

    // 为 AroundTarget 允许的类型列表添加向量类型对象
    default AroundTarget.AllowedTypes.Add(VectorObject);

    /**
     * @brief 蓝图可重写的函数，AI 控制器执行此任务时调用。
     * 若 VectorObject 为空，会创建一个新的向量类型黑板键对象，
     * 然后调用 ExecuteImpl 函数执行实际逻辑，并根据其返回结果结束任务执行。
     * @param OwnerController 执行此任务的 AI 控制器。
     * @param ControlledPawn AI 控制器控制的 pawn 对象。
     */
    UFUNCTION(BlueprintOverride)
    void ExecuteAI(AAIController OwnerController, APawn ControlledPawn)
    {
        // 若 VectorObject 为空，创建一个新的向量类型黑板键对象
        if (VectorObject == nullptr)
        {
            VectorObject = Cast<UBlackboardKeyType_Vector>(NewObject(Class.DefaultObject, UBlackboardKeyType_Vector, n"VectorType"));
        }
        // 调用 ExecuteImpl 函数执行实际逻辑，并根据返回结果结束任务执行
        FinishExecute(ExecuteImpl(OwnerController, ControlledPawn));
    }

    /**
     * @brief 执行实际绕目标移动逻辑的函数。
     * 从黑板中获取目标 Actor，若目标存在，在其周围可导航区域随机选择一个位置，
     * 将该位置存储到黑板中，并绘制调试球体标记该位置。
     * @param OwnerController 执行此任务的 AI 控制器。
     * @param ControlledPawn AI 控制器控制的 pawn 对象。
     * @return 若成功找到随机位置并存储到黑板返回 true，否则返回 false。
     */
    private bool ExecuteImpl(AAIController OwnerController, APawn ControlledPawn)
    {
        // 通过 AI 控制器获取黑板组件
        UBlackboardComponent BlackboardComponent = AIHelper::GetBlackboard(OwnerController);
        // 从黑板中获取要跟随的目标 Actor
        AActor Target = Cast<AActor>(BlackboardComponent.GetValueAsObject(AuraConst::AI_Blackboard_Key_TargetToFollow));
        // 若目标为空，无法执行绕目标移动，返回 false
        if (Target == nullptr)
        {
            return false;
        }

        // 用于存储随机选择的位置
        FVector RandomLocation;
        // 尝试在目标周围 300 单位半径的可导航区域内随机选择一个位置
        if (!UNavigationSystemV1::GetRandomLocationInNavigableRadius(Target.GetActorLocation(), RandomLocation, 300))
        {
            // 若未找到合适位置，返回 false
            return false;
        }

        // 将随机选择的位置存储到黑板中指定的键下
        BlackboardComponent.SetValueAsVector(AroundTarget.SelectedKeyName, RandomLocation);
        // 注释掉的代码，可用于让 AI 直接移动到随机位置
        // AIHelper::SimpleMoveToLocation(OwnerController, RandomLocation);
        // 在随机位置绘制一个调试球体，半径为 10，分段数为 12，颜色为深粉色，持续时间 0.5 秒
        System::DrawDebugSphere(RandomLocation, 10, 12, FLinearColor::DPink, 0.5);
        // 成功找到并存储随机位置，返回 true
        return true;
    }
}
