/**
 * @class UBTService_FindNearestPlayer
 * @brief 继承自 UBTService_BlueprintBase，该类用于在游戏中查找距离最近的玩家，
 * 并将相关信息（如最近玩家对象、距离、是否能远程攻击）更新到黑板（Blackboard）中。
 */
class UBTService_FindNearestPlayer : UBTService_BlueprintBase
{
    // -------------------- Properties --------------------
    /**
     * @brief 私有属性，用于存储对象类型的黑板键类型实例，初始化为空指针。
     * 后续会在 ActivationAI 函数中初始化，用于指定黑板键允许的对象类型。
     */
    private UBlackboardKeyType_Object ObjectObject = nullptr;
    /**
     * @brief 私有属性，用于存储布尔类型的黑板键类型实例，初始化为空指针。
     * 后续会在 ActivationAI 函数中初始化，用于指定黑板键允许的布尔类型。
     */
    private UBlackboardKeyType_Bool BoolType = nullptr;
    /**
     * @brief 私有属性，用于存储浮点类型的黑板键类型实例，初始化为空指针。
     * 后续会在 ActivationAI 函数中初始化，用于指定黑板键允许的浮点类型。
     */
    private UBlackboardKeyType_Float FloatType = nullptr;

    /**
     * @brief 公开属性，黑板键选择器，用于选择要跟踪的目标。
     * 允许的类型为对象类型，会在 AI 激活时关联到具体的黑板键。
     */
    UPROPERTY()
    FBlackboardKeySelector TargetToFollow;
    // 默认将对象类型添加到 TargetToFollow 允许的类型列表中
    default TargetToFollow.AllowedTypes.Add(ObjectObject);

    /**
     * @brief 公开属性，黑板键选择器，用于判断 AI 是否处于受击反应状态。
     * 允许的类型为布尔类型，会在 AI 激活时关联到具体的黑板键。
     */
    UPROPERTY()
    FBlackboardKeySelector IsHitReacting;
    // 默认将布尔类型添加到 IsHitReacting 允许的类型列表中
    default IsHitReacting.AllowedTypes.Add(BoolType);

    /**
     * @brief 公开属性，黑板键选择器，用于判断 AI 是否可以进行远程攻击。
     * 允许的类型为布尔类型，会在 AI 激活时关联到具体的黑板键。
     */
    UPROPERTY()
    FBlackboardKeySelector CanRangeAttack;
    // 默认将布尔类型添加到 CanRangeAttack 允许的类型列表中
    default CanRangeAttack.AllowedTypes.Add(BoolType);

    /**
     * @brief 公开属性，黑板键选择器，用于存储 AI 到目标的距离。
     * 允许的类型为浮点类型，会在 AI 激活时关联到具体的黑板键。
     */
    UPROPERTY()
    FBlackboardKeySelector DistanceToTarget;
    // 默认将浮点类型添加到 DistanceToTarget 允许的类型列表中
    default DistanceToTarget.AllowedTypes.Add(FloatType);

    // -------------------- Functions --------------------

    /**
     * @brief AI 激活时调用的函数，用于初始化黑板键类型实例并进行关键检查。
     * @param OwnerController 控制该 AI 行为的 AI 控制器实例。
     * @param ControlledPawn 该 AI 控制器所控制的角色实例。
     */
    UFUNCTION(BlueprintOverride)
    void ActivationAI(AAIController OwnerController, APawn ControlledPawn)
    {
        // 检查 TargetToFollow 选中的黑板键名称是否与常量定义的一致，确保键名正确
        check(TargetToFollow.SelectedKeyName == AuraConst::AI_Blackboard_Key_TargetToFollow);
        // 创建一个新的 UBlackboardKeyType_Object 实例，并将其转换为 UBlackboardKeyType_Object 类型
        ObjectObject = Cast<UBlackboardKeyType_Object>(NewObject(Class.DefaultObject, UBlackboardKeyType_Object, n"ObjectType"));
        // 创建一个新的 UBlackboardKeyType_Bool 实例，并将其转换为 UBlackboardKeyType_Bool 类型
        BoolType = Cast<UBlackboardKeyType_Bool>(NewObject(Class.DefaultObject, UBlackboardKeyType_Bool, n"BoolType"));
        // 创建一个新的 UBlackboardKeyType_Float 实例，并将其转换为 UBlackboardKeyType_Float 类型
        FloatType = Cast<UBlackboardKeyType_Float>(NewObject(Class.DefaultObject, UBlackboardKeyType_Float, n"FloatType"));
    }

    /**
     * @brief AI 每帧更新时调用的函数，用于查找距离最近的玩家并更新黑板数据。
     * @param OwnerController 控制该 AI 行为的 AI 控制器实例。
     * @param ControlledPawn 该 AI 控制器所控制的角色实例。
     * @param DeltaSeconds 从上一帧到当前帧的时间间隔，单位为秒。
     */
    UFUNCTION(BlueprintOverride)
    void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
    {
        // 打印当前控制的角色正在进行 TickAI 操作（注释状态，可取消注释用于调试）
        // Print(f"{ControlledPawn.GetName()} is TickAI");

        // 检查当前控制的角色是否为玩家，如果是则无需查找最近玩家
        if (ControlledPawn.ActorHasTag(AuraConst::PlayerTag))
        {
            Print("Player does not need to find a player");
            return;
        }

        // 用于存储所有带有玩家标签的角色的数组
        TArray<AActor> Players;
        // 调用 Gameplay 命名空间下的函数，获取所有带有玩家标签的角色
        Gameplay::GetAllActorsWithTag(AuraConst::PlayerTag, Players);

        // 将当前控制的角色转换为 AAuraCharacterBase 类型
        AAuraCharacterBase ControlledCharacter = Cast<AAuraCharacterBase>(ControlledPawn);
        // 如果转换失败，说明当前控制的角色不是 AAuraCharacterBase 类型，不支持处理
        if (ControlledCharacter == nullptr)
        {
            Print("Only support AuraCharacterBase");
            return;
        }

        // 如果没有找到带有玩家标签的角色，打印提示信息并返回
        if (Players.Num() == 0)
        {
            Print("No player found");
            return;
        }

        // 获取当前控制角色的位置
        FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();

        // 用于存储距离最近的玩家对象，初始化为空指针
        AActor NearestPlayer = nullptr;
        // 用于存储到最近玩家的距离，初始化为一个较大的值
        float  NearestDistance = 10000;

        // 如果只有一个玩家，直接将其设为最近玩家并计算距离
        if (Players.Num() == 1)
        {
            NearestPlayer = Players[0];
            NearestDistance = NearestPlayer.GetActorLocation().Distance(ControlledPawnLocation);
        }
        else
        {
            // 先将第一个玩家设为最近玩家
            NearestPlayer = Players[0];
            // 遍历除第一个玩家外的所有玩家
            for (int i = 1; i < Players.Num(); i++)
            {
                // 计算当前玩家与控制角色的距离
                float Distance = Players[i].GetActorLocation().Distance(ControlledPawnLocation);
                // 如果当前距离小于之前记录的最近距离，更新最近距离和最近玩家
                if (Distance < NearestDistance)
                {
                    NearestDistance = Distance;
                    NearestPlayer = Players[i];
                }
            }
        }

        // 通过 AI 控制器获取黑板组件
        UBlackboardComponent BlackboardComponent = AIHelper::GetBlackboard(OwnerController);
        // 将最近玩家对象存储到黑板中对应的键下
        BlackboardComponent.SetValueAsObject(TargetToFollow.SelectedKeyName, NearestPlayer);
        // 将到最近玩家的距离存储到黑板中对应的键下
        BlackboardComponent.SetValueAsFloat(DistanceToTarget.SelectedKeyName, NearestDistance);
        // 将当前控制角色是否能远程攻击的信息存储到黑板中对应的键下
        BlackboardComponent.SetValueAsBool(CanRangeAttack.SelectedKeyName, ControlledCharacter.CanRangeAttack());
    }
}