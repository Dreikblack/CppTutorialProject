#pragma once
#include "Leadwerks.h"
#include "VRPlayer.h"

using namespace Leadwerks;

VRPlayer::VRPlayer()
{
	name = "VRPlayer";
}

void VRPlayer::Start()
{
	auto entity = GetEntity();
	entity->SetHidden(true);
	hmd = GetHmd(entity->GetWorld());
	hmd->SetOffset(entity->GetPosition(true), entity->GetRotation(true));
}

//This method will work with simple components
shared_ptr<Component> VRPlayer::Copy()
{
	return std::make_shared<VRPlayer>(*this);
}