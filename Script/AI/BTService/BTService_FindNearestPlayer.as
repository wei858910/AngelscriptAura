/*
怪物行为：
1. 如果是近战怪，移动到玩家附近并发起攻击
*/

class UBTService_FindNearestPlayer : UBTService_BlueprintBase
{
    // -------------------- Properties --------------------
    private UBlackboardKeyType_Object ObjectObject = nullptr;
    private UBlackboardKeyType_Bool BoolType = nullptr;
    private UBlackboardKeyType_Float FloatType = nullptr;

    UPROPERTY()
    FBlackboardKeySelector TargetToFollow;
    default TargetToFollow.AllowedTypes.Add(ObjectObject);

    UPROPERTY()
    FBlackboardKeySelector IsHitReacting;
    default IsHitReacting.AllowedTypes.Add(BoolType);

    UPROPERTY()
    FBlackboardKeySelector CanRangeAttack;
    default CanRangeAttack.AllowedTypes.Add(BoolType);

    UPROPERTY()
    FBlackboardKeySelector DistanceToTarget;
    default DistanceToTarget.AllowedTypes.Add(FloatType);

    // -------------------- Functions --------------------

    UFUNCTION(BlueprintOverride)
    void ActivationAI(AAIController OwnerController, APawn ControlledPawn)
    {
        check(TargetToFollow.SelectedKeyName == AuraConst::AI_Blackboard_Key_TargetToFollow);
        ObjectObject = Cast<UBlackboardKeyType_Object>(NewObject(Class.DefaultObject, UBlackboardKeyType_Object, n"ObjectType"));
        BoolType = Cast<UBlackboardKeyType_Bool>(NewObject(Class.DefaultObject, UBlackboardKeyType_Bool, n"BoolType"));
        FloatType = Cast<UBlackboardKeyType_Float>(NewObject(Class.DefaultObject, UBlackboardKeyType_Float, n"FloatType"));
    }

    UFUNCTION(BlueprintOverride)
    void TickAI(AAIController OwnerController, APawn ControlledPawn, float DeltaSeconds)
    {
        // Print(f"{ControlledPawn.GetName()} is TickAI");

        if (ControlledPawn.ActorHasTag(AuraConst::PlayerTag))
        {
            Print("Player does not need to find a player");
            return;
        }

        TArray<AActor> Players;
        Gameplay::GetAllActorsWithTag(AuraConst::PlayerTag, Players);

        AAuraCharacterBase ControlledCharacter = Cast<AAuraCharacterBase>(ControlledPawn);
        if (ControlledCharacter == nullptr)
        {
            Print("Only support AuraCharacterBase");
            return;
        }

        if (Players.Num() == 0)
        {
            Print("No player found");
            return;
        }

        FVector ControlledPawnLocation = ControlledPawn.GetActorLocation();

        // Find the nearest player
        AActor NearestPlayer = nullptr;
        float  NearestDistance = 10000;

        if (Players.Num() == 1)
        {
            NearestPlayer = Players[0];
            NearestDistance = NearestPlayer.GetActorLocation().Distance(ControlledPawnLocation);
        }
        else
        {
            NearestPlayer = Players[0];
            for (int i = 1; i < Players.Num(); i++)
            {
                float Distance = Players[i].GetActorLocation().Distance(ControlledPawnLocation);
                if (Distance < NearestDistance)
                {
                    NearestDistance = Distance;
                    NearestPlayer = Players[i];
                }
            }
        }

        UBlackboardComponent BlackboardComponent = AIHelper::GetBlackboard(OwnerController);
        BlackboardComponent.SetValueAsObject(TargetToFollow.SelectedKeyName, NearestPlayer);
        BlackboardComponent.SetValueAsFloat(DistanceToTarget.SelectedKeyName, NearestDistance);
        BlackboardComponent.SetValueAsBool(CanRangeAttack.SelectedKeyName, ControlledCharacter.CanRangeAttack());
    }
}