#pragma once
#include "UltraEngine.h"

#include "Components/AI/Monster.h"

#include "Components/Appearance/ChangeVisibility.h"
#include "Components/Appearance/ChangeEmission.h"

#include "Components/Logic/Relay.h"

#include "Components/Motion/Mover.h"

#include "Components/Physics/SlidingDoor.h"
#include "Components/Physics/SwingingDoor.h"
#include "Components/Physics/Impulse.h"

#include "Components/Player/CameraControls.h"
#include "Components/Player/FPSPlayer.h"
#include "Components/Player/VRPlayer.h"

#include "Components/Sound/AmbientNoise.h"
#include "Components/Sound/ImpactNoise.h"

#include "Components/Triggers/CollisionTrigger.h"
#include "Components/Triggers/PushButton.h"

#include "Components/Weapons/FPSGun.h"
#include "Components/Weapons/Bullet.h"
#include "Components/Logic/WayPoint.h"
#include "Components/Motion/WayMover.h"
#include "Components/Player/TopDownCamera.h"
#include "Components/AI/Unit.h"
#include "Components/Player/StrategyController.h"
#include "Components/Appearance/ParticleEffect.h"

void RegisterComponents()
{
    RegisterComponent<Monster>();

    RegisterComponent<ChangeVisibility>();
    RegisterComponent<ChangeEmission>();

    RegisterComponent<Relay>();

    RegisterComponent<Mover>();
    
    RegisterComponent<SlidingDoor>();
    RegisterComponent<SwingingDoor>();
    RegisterComponent<Impulse>();

    RegisterComponent<CameraControls>();
    RegisterComponent<FPSPlayer>();
    RegisterComponent<VRPlayer>();
    
    RegisterComponent<AmbientNoise>();
    RegisterComponent<ImpactNoise>();
    
    RegisterComponent<CollisionTrigger>();
    RegisterComponent<PushButton>();

    RegisterComponent<Bullet>();
    RegisterComponent<FPSGun>();

    RegisterComponent<WayPoint>();
    RegisterComponent<WayMover>();
    RegisterComponent<TopDownCamera>();
    RegisterComponent<Unit>();
    RegisterComponent<StrategyController>();
    RegisterComponent<ParticleEffect>();  
}

