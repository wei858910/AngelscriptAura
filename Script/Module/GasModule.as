/**
 * @class UGasModule
 * @brief 继承自 UObject，用于管理角色的能力系统模块，处理属性集注册、属性值缓存和属性变更回调等功能。
 */
class UGasModule : UObject
{
    // -------------------- Varibles --------------------
    /**
     * @brief 拥有该气体模块的角色实例，用于关联模块与具体角色。
     */
    AAuraCharacterBase OwnerCharacter;

    /**
     * @brief 缓存的属性值映射表，键为属性名，值为属性的当前值，用于快速获取属性值。
     */
    private TMap<FName, float32> CachedAttributeValues;
    /**
     * @brief 角色的属性集实例，用于管理角色的各项属性。
     */
    private UAuraAttributeSet AttributeSet;

    // -------------------- Functions --------------------
    /**
     * @brief 初始化气体模块，将模块与角色关联，并注册属性集。
     * @param InOwnerCharacter 拥有该气体模块的角色实例。
     */
    void Init(AAuraCharacterBase InOwnerCharacter)
    {
        // 将传入的角色实例赋值给 OwnerCharacter
        OwnerCharacter = InOwnerCharacter;

        // 获取角色的能力系统组件
        UAngelscriptAbilitySystemComponent ASC = OwnerCharacter.AbilitySystem;
        // 注册属性集注册回调函数，当属性集注册时调用 OnAttributeSetRegistered 函数
        ASC.OnAttributeSetRegistered(this, n"OnAttributeSetRegistered");

        // 向能力系统组件注册属性集，并将其转换为 UAuraAttributeSet 类型
        AttributeSet = Cast<UAuraAttributeSet>(ASC.RegisterAttributeSet(UAuraAttributeSet.Get()));
        // 初始化能力系统的 Actor 信息
        ASC.InitAbilityActorInfo(OwnerCharacter, OwnerCharacter);
    }

    /**
     * @brief 获取拥有该气体模块角色的能力系统组件。
     * @return 角色的能力系统组件实例。
     */
    UAngelscriptAbilitySystemComponent GetASC()
    {
        return OwnerCharacter.AbilitySystem;
    }

    /**
     * @brief 当属性集注册时调用的回调函数，注册属性变更回调并初始化属性映射。
     * @param NewAttributeSet 新注册的属性集实例。
     */
    UFUNCTION()
    void OnAttributeSetRegistered(UAngelscriptAttributeSet NewAttributeSet)
    {
        // 将新注册的属性集转换为 UAuraAttributeSet 类型
        UAuraAttributeSet AuraAttributeSet = Cast<UAuraAttributeSet>(NewAttributeSet);
        // 若转换失败，打印错误信息并返回
        if (AuraAttributeSet == nullptr)
        {
            Print(f"OnAttributeSetRegistered {NewAttributeSet.Name} is not UAuraAttributeSet");
            return;
        }

        // 初始化属性集的属性映射
        AuraAttributeSet.InitAttributesMapping();

        // 获取角色的能力系统组件
        UAngelscriptAbilitySystemComponent ASC = this.GetASC();

        // 注释说明：此方法未生效，具体原因未知
        // 尝试注册属性变更回调函数，但未生效
        // ASC.RegisterAttributeChangedCallback(AttributeSetClass, n"Health", this, n"OnAttributeChanged");

        // 注册属性变更回调函数，当属性变更时调用 OnAttributeChanged 函数
        ASC.OnAttributeChanged.AddUFunction(this, n"OnAttributeChanged");

        // 获取属性集的类
        UClass AttributeSetClass = AuraAttributeSet.GetClass();
        // 遍历属性集中的所有属性
        for (auto Element : AuraAttributeSet.GetAllAttributes())
        {
            // 获取属性名
            FName AttributeName = Element.Key;
            // 为每个属性注册回调函数，确保属性变更时能触发 OnAttributeChanged 函数
            ASC.RegisterCallbackForAttribute(AttributeSetClass, AttributeName);
        }
    }

    /**
     * @brief 当属性值发生变更时调用的回调函数，更新缓存的属性值并通知角色。
     * @param AttributeChangeData 包含属性变更信息的结构体。
     */
    UFUNCTION()
    private void OnAttributeChanged(const FAngelscriptModifiedAttribute&in AttributeChangeData)
    {
        // 更新缓存的属性值
        CachedAttributeValues.Add(AttributeChangeData.Name, AttributeChangeData.NewValue);
        // 通知拥有该气体模块的角色属性已变更
        OwnerCharacter.OnAttributeChanged(AttributeChangeData);
    }

    /**
     * @brief 获取指定属性的当前值，若缓存中不存在则从属性集获取并缓存。
     * @param AttributeName 要获取的属性名。
     * @return 指定属性的当前值。
     */
    float32 GetAttributeValue(FName AttributeName)
    {
        // 若缓存中不包含该属性名
        if (!CachedAttributeValues.Contains(AttributeName))
        {
            // 从属性集中获取该属性的当前值并添加到缓存中
            CachedAttributeValues.Add(AttributeName, AttributeSet.GetAttribute(AttributeName).GetCurrentValue());
        }
        // 返回缓存中的属性值
        return CachedAttributeValues[AttributeName];
    }

    // TODO: 这样直接设置不生效，不会回调到OnAttributeChanged里，导致即使最简单的对一级属性的加减，也要通过GE来实现，调查下原因
    // /**
    //  * @brief 设置指定属性的基础值和当前值（当前方法未生效）。
    //  * @param AttributeName 要设置的属性名。
    //  * @param Value 要设置的属性值。
    //  */
    // void SetAttributeValue(FName AttributeName, float32 Value)
    // {
    // 	FAngelscriptGameplayAttributeData& AttributeData = AttributeSet.GetAttribute(AttributeName);
    // 	AttributeData.SetBaseValue(Value);
    // 	AttributeData.SetCurrentValue(Value);
    // }

    // /**
    //  * @brief 为指定属性的基础值和当前值增加指定数值（当前方法未生效）。
    //  * @param AttributeName 要增加的属性名。
    //  * @param Value 要增加的数值。
    //  */
    // void AddAttributeValue(FName AttributeName, float32 Value)
    // {
    // 	FAngelscriptGameplayAttributeData& AttributeData = AttributeSet.GetAttribute(AttributeName);
    // 	AttributeData.SetBaseValue(AttributeData.GetBaseValue() + Value);
    // 	AttributeData.SetCurrentValue(AttributeData.GetCurrentValue() + Value);
    // }
}