/**
 * @class AAuraEnemy
 * @brief 继承自 AAuraCharacterBase，代表游戏中的敌方角色类。
 * 该类包含敌方角色的属性设置、变量声明以及一系列功能函数，
 * 用于处理敌方角色的初始化、属性变更、行为树运行等逻辑。
 */
class AAuraEnemy : AAuraCharacterBase
{
    // -------------------- Properties --------------------
    /**
     * @brief 默认组件，生命值条组件，用于显示敌方角色的生命值状态。
     */
    UPROPERTY(DefaultComponent)
    UWidgetComponent HealthBar;

    /**
     * @brief 敌方角色的行为树，属于 Aura 类别，用于控制敌方角色的 AI 行为。
     */
    UPROPERTY(Category = Aura)
    UBehaviorTree BehaviorTree;

    // 设置胶囊体组件对可见性碰撞通道的响应为阻挡
    default CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
    // 设置胶囊体组件对投射物碰撞通道的响应为重叠
    default CapsuleComponent.SetCollisionResponseToChannel(AuraEnum::ECC_Projectile, ECollisionResponse::ECR_Overlap);

    // 为敌方角色添加敌人标签，用于标识该角色为敌人
    default Tags.Add(AuraConst::EnemyTag);
    // 默认注释掉的代码，可设置角色的最大移动速度为 120
    // default CharacterMovement.MaxSpeed = 120;
    // 禁用控制器控制角色的 Pitch 旋转
    default bUseControllerRotationPitch = false;
    // 禁用控制器控制角色的 Yaw 旋转
    default bUseControllerRotationYaw = false;
    // 禁用控制器控制角色的 Roll 旋转
    default bUseControllerRotationRoll = false;
    // 让角色使用控制器期望的旋转
    default CharacterMovement.bUseControllerDesiredRotation = true;

    // -------------------- Variables --------------------

    // -------------------- Functions --------------------

    /**
     * @brief 蓝图可重写的函数，当敌方角色开始游戏时调用。
     * 调用父类的 BeginPlay 函数，初始化生命值条组件，并注册拥有标签更新的回调函数。
     */
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // 调用父类的 BeginPlay 函数
        Super::BeginPlay();

        // 将生命值条组件附加到角色的根组件上
        HealthBar.AttachToComponent(GetRootComponent());
        // 将生命值条组件的小部件转换为 UAUW_HealthBar 类型
        UAUW_HealthBar HealthBarWidget = Cast<UAUW_HealthBar>(HealthBar.GetWidget());
        // 若转换成功
        if (HealthBarWidget != nullptr)
        {
            // 设置生命值条组件的拥有者角色为当前敌方角色
            HealthBarWidget.OwnerCharacter = this;
            // 默认注释掉的代码，可设置生命值条的进度为 100%
            // HealthBarWidget.ProgressBar_HealthBar.SetPercent(1);
        }

        // 注册拥有标签更新的回调函数，当拥有的游戏玩法标签更新时调用 OnOwnedTagUpdated 函数
        AbilitySystem.OnOwnedTagUpdated.AddUFunction(this, n"OnOwnedTagUpdated");
    }

    /**
     * @brief 高亮显示敌方角色。
     * 开启角色骨骼网格组件和武器组件的自定义深度渲染，使角色在视觉上高亮。
     */
    void Highlight()
    {
        // 开启角色骨骼网格组件的自定义深度渲染
        Mesh.RenderCustomDepth = true;
        // 开启武器组件的自定义深度渲染
        Weapon.RenderCustomDepth = true;
    }

    /**
     * @brief 取消敌方角色的高亮显示。
     * 关闭角色骨骼网格组件和武器组件的自定义深度渲染，恢复角色正常视觉效果。
     */
    void Unhighlight()
    {
        // 关闭角色骨骼网格组件的自定义深度渲染
        Mesh.RenderCustomDepth = false;
        // 关闭武器组件的自定义深度渲染
        Weapon.RenderCustomDepth = false;
    }

    /**
     * @brief 当拥有的游戏玩法标签更新时调用的回调函数。
     * 若更新的标签为受击反应标签，则更新黑板中受击反应状态的值。
     * @param Tag 更新的游戏玩法标签。
     * @param TagExists 标签是否存在的标志。
     */
    UFUNCTION()
    private void OnOwnedTagUpdated(const FGameplayTag&in Tag, bool TagExists)
    {
        // 默认注释掉的代码，可打印更新的标签信息
        // Print(f"OnOwnedTagUpdated: {Tag.ToString() =} {TagExists =}");
        // 若更新的标签为受击反应标签
        if (Tag == GameplayTags::Effects_HitReact)
        {
            // 获取 AI 控制器的黑板组件，并设置受击反应状态的值
            AIHelper::GetBlackboard(Controller).SetValueAsBool(AuraConst::AI_Blackboard_Key_IsHitReacting, TagExists);
        }
    }

    /**
     * @brief 蓝图可重写的函数，当敌方角色被控制时调用。
     * 在服务器端获取 AI 控制器，并运行预设的行为树。
     * @param NewController 控制该敌方角色的新控制器。
     */
    UFUNCTION(BlueprintOverride)
    void Possessed(AController NewController)
    {
        // 若当前处于服务器端
        if (HasAuthority())
        {
            // 将控制器转换为 AAuraAIController 类型
            AAuraAIController AIController = Cast<AAuraAIController>(GetController());
            // 若转换成功
            if (AIController != nullptr)
            {
                // 运行预设的行为树
                AIController.RunBehaviorTree(BehaviorTree);
            }
        }
    }

    /**
     * @brief 重写父类的属性变更回调函数。
     * 当生命值属性发生变化时，更新生命值条组件显示的百分比。
     * @param AttributeChangeData 包含属性变更信息的结构体。
     */
    void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData) override
    {
        // 若变更的属性为生命值属性
        if (AttributeChangeData.Name == AuraAttributes::Health)
        {
            // 默认注释掉的代码，可根据属性变更数据直接设置生命值条的百分比
            // HealthBar.ProgressBar_HealthBar.SetPercent(AttributeChangeData.NewValue / AttributeChangeData.BaseValue);
            // 将生命值条组件的小部件转换为 UAUW_HealthBar 类型
            UAUW_HealthBar HealthBarWidget = Cast<UAUW_HealthBar>(HealthBar.GetWidget());
            // 若转换成功
            if (HealthBarWidget != nullptr)
            {
                // 调用生命值条组件的 SetPercent 函数，根据当前生命值和最大生命值设置百分比
                HealthBarWidget.SetPercent(GasModule.GetAttributeValue(AuraAttributes::Health), GasModule.GetAttributeValue(AuraAttributes::MaxHealth));
            }
        }
    }
}
