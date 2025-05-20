#pragma once
#include "Leadwerks.h"

// This file was automatically generated

#include "Components/AI/Monster.h"
#include "Components/Appearance/ChangeEmission.h"
#include "Components/Appearance/ChangeVisibility.h"
#include "Components/Logic/Relay.h"
#include "Components/Motion/Mover.h"
#include "Components/Physics/Impulse.h"
#include "Components/Physics/SlidingDoor.h"
#include "Components/Physics/SwingingDoor.h"
#include "Components/Player/CameraControls.h"
#include "Components/Player/FPSPlayer.h"
#include "Components/Player/VRPlayer.h"
#include "Components/Sound/AmbientNoise.h"
#include "Components/Sound/ImpactNoise.h"
#include "Components/Triggers/CollisionTrigger.h"
#include "Components/Triggers/PushButton.h"
#include "Components/Weapons/Bullet.h"
#include "Components/Weapons/FPSGun.h"

void RegisterComponents()
{
	RegisterComponent<Monster>();
	RegisterComponent<ChangeEmission>();
	RegisterComponent<ChangeVisibility>();
	RegisterComponent<Relay>();
	RegisterComponent<Mover>();
	RegisterComponent<Impulse>();
	RegisterComponent<SlidingDoor>();
	RegisterComponent<SwingingDoor>();
	RegisterComponent<CameraControls>();
	RegisterComponent<FPSPlayer>();
	RegisterComponent<VRPlayer>();
	RegisterComponent<AmbientNoise>();
	RegisterComponent<ImpactNoise>();
	RegisterComponent<CollisionTrigger>();
	RegisterComponent<PushButton>();
	RegisterComponent<Bullet>();
	RegisterComponent<FPSGun>();
}
