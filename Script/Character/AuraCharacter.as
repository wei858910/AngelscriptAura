/**
 * @class AAuraCharacter
 * @brief 继承自 AAuraCharacterBase，代表游戏中的玩家角色类。
 * 该类包含玩家角色的相机组件、玩家模块管理器等，同时处理属性变更事件和游戏开始逻辑。
 */
class AAuraCharacter : AAuraCharacterBase
{
    /**
     * @brief 默认组件，弹簧臂组件，用于控制相机与角色的相对位置和旋转。
     * 该组件会使相机保持在角色后方一定距离，并可随角色移动而移动。
     */
    UPROPERTY(DefaultComponent)
    USpringArmComponent SpringArm;
    // 设置弹簧臂的相对旋转，使相机向下倾斜 45 度
    default SpringArm.SetRelativeRotation(FRotator(-45, 0, 0));
    // 设置弹簧臂的目标长度为 850 单位，即相机与角色的距离
    default SpringArm.TargetArmLength = 850;

    /**
     * @brief 默认组件，相机组件，附加到弹簧臂上，用于控制玩家的视角。
     * 相机的位置和旋转由弹簧臂决定。
     */
    UPROPERTY(DefaultComponent, Attach = "SpringArm")
    UCameraComponent Camera;

    // 设置胶囊体组件对敌人投射物碰撞通道的响应为重叠
    default CapsuleComponent.SetCollisionResponseToChannel(AuraEnum::ECC_EnemyProjectile, ECollisionResponse::ECR_Overlap);

    // --------------------------------------
    /**
     * @brief 玩家模块管理器实例，用于管理玩家的各种模块功能。
     */
    UPlayerModuleMgr PlayerModuleMgr;

    // --------- ctor --------
    // 设置角色移动时自动朝向移动方向
    default CharacterMovement.bOrientRotationToMovement = true;
    // 设置角色的旋转速率，每秒绕 Yaw 轴旋转 400 度
    default CharacterMovement.RotationRate = FRotator(0, 400, 0);
    // 设置角色移动限制在一个平面上
    default CharacterMovement.bConstrainToPlane = true;
    // 设置角色开始移动时立即对齐到平面
    default CharacterMovement.bSnapToPlaneAtStart = true;
    // 禁用控制器控制角色的 Pitch 旋转
    default bUseControllerRotationPitch = false;
    // 禁用控制器控制角色的 Roll 旋转
    default bUseControllerRotationRoll = false;
    // 禁用控制器控制角色的 Yaw 旋转
    default bUseControllerRotationYaw = false;
    // 为角色添加玩家标签，用于标识该角色为玩家
    default Tags.Add(AuraConst::PlayerTag);

    /**
     * @brief 重写父类的属性变更回调函数。
     * 当角色属性发生变化时，广播属性变更事件。
     * @param AttributeChangeData 包含属性变更信息的结构体。
     */
    void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData) override
    {
        // 广播属性变更事件
        AuraUtil::GameInstance().EventMgr.OnAttributeChangedEvent.Broadcast(AttributeChangeData);
    }

    // /**
    //  * @brief 初始化玩家模块管理器。
    //  * 创建玩家模块管理器实例并调用其构造函数和初始化函数。
    //  */
    // void InitPlayerModuleMgr()
    // {
    // 	// 创建玩家模块管理器实例
    // 	PlayerModuleMgr = Cast<UPlayerModuleMgr>(NewObject(this, UPlayerModuleMgr::StaticClass(), n"UPlayerModuleMgr"));
    // 	// 调用玩家模块管理器的构造函数
    // 	PlayerModuleMgr.Ctor(this);
    // 	// 调用玩家模块管理器的初始化函数
    // 	PlayerModuleMgr.Init();
    // }

    // /**
    //  * @brief 重写角色被控制时的回调函数。
    //  * 在服务器端初始化玩家模块管理器。
    //  * @param NewController 控制该角色的新控制器。
    //  */
    // UFUNCTION(BlueprintOverride)
    // void Possessed(AController NewController)
    // {
    // 	// Init player module manager for the server
    // 	InitPlayerModuleMgr();
    // }

    // --------- functions ----------

    /**
     * @brief 重写角色开始游戏时的回调函数。
     * 初始化玩家模块管理器，并调用父类的 BeginPlay 函数。
     */
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // const bool IsDedicatedServer = System::IsDedicatedServer();
        // 创建玩家模块管理器实例
        PlayerModuleMgr = Cast<UPlayerModuleMgr>(NewObject(this, UPlayerModuleMgr, n"UPlayerModuleMgr"));
        // 调用玩家模块管理器的构造函数
        PlayerModuleMgr.Ctor(this);
        // 调用玩家模块管理器的初始化函数
        PlayerModuleMgr.Init();

        // 调用父类的 BeginPlay 函数
        Super::BeginPlay();
    }
}
