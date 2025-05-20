#pragma once
#include "Leadwerks.h"
#include "FPSWeapon.h"

using namespace Leadwerks;

void FPSWeapon::Start()
{
	auto entity = GetEntity();
	auto model = entity->As<Model>();

	// Right now, skip decals. Maybe we want exclusive decals on the gun in the future?
	entity->SetDecalLayers(0, true);
	entity->SetMass(0);
	entity->SetCollider(NULL);
	entity->SetPickMode(PICK_NONE);
	entity->SetNavObstacle(false);
	entity->SetCollisionType(COLLISION_NONE);

	// This ensures the weapon is ready to be drawn
	if (model) model->Animate("get", 1.0f, 0, ANIMATION_STOP, 0);
}

void FPSWeapon::GetHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
	//Print("ReloadHook");
	auto gun = std::dynamic_pointer_cast<FPSWeapon>(extra);
	gun->getting = false;
}

bool FPSWeapon::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
	if (properties["refirerate"].is_integer()) refirerate = float(properties["refirerate"]);
	return true;
}

bool FPSWeapon::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
	properties["refirerate"] = refirerate;
	return true;
}

void FPSWeapon::DetachFromPlayer(std::shared_ptr<Component> playercomponent)
{
	auto entity = GetEntity();
	auto model = entity->As<Model>();
	model->StopAnimation();
	entity->SetHidden(true);
	entity->SetParent(NULL, false);
	equipped = false;
}

void FPSWeapon::PutAway()
{
	puttingaway = true;
	auto entity = GetEntity();
	if (not entity) return;
	auto model = entity->As<Model>();
	if (model) model->Animate("hide", 2.0, 250, ANIMATION_ONCE);
}

void FPSWeapon::GetOut()
{
	getting = true;
	auto entity = GetEntity();
	if (not entity) return;
	auto model = entity->As<Model>();
	if (model)
	{
		model->StopAnimation();
		model->Animate("get", 1.0f, 0, ANIMATION_STOP, 0);
		model->Animate("get", 2.0f, 0, ANIMATION_ONCE, 0);
	}
}

void FPSWeapon::AttachToPlayer(std::shared_ptr<Component> playercomponent)
{
	// Set up the camera for the viewmodel.
	Start();

	auto entity = GetEntity();
	auto world = entity->GetWorld();

	auto player = playercomponent->As<FPSPlayer>();
	if (player)
	{
		auto playercam = player->camera;
		if (playercam)
		{
			/*if (drawonlayer)
			{
				viewmodelcam = CreateCamera(world);
				viewmodelcam->SetClearColor(0, 0, 0, 0);
				viewmodelcam->SetClearMode(CLEAR_DEPTH);
				viewmodelcam->SetMatrix(playercam->GetMatrix(true), true);
				viewmodelcam->SetFov(viewmodelfov);
				viewmodelcam->SetRange(0.001f, playercam->GetRange().y);
				viewmodelcam->SetOrder(RENDERLAYER_VIEWMODEL);
				viewmodelcam->SetRenderLayers(RENDERLAYER_VIEWMODEL);
				viewmodelcam->SetParent(playercam, false);

				entity->SetParent(viewmodelcam);

				entity->SetRenderLayers(RENDERLAYER_VIEWMODEL);
			}
			else
			{*/
				playercam->SetRange(0.001f, playercam->GetRange().y);
				entity->SetParent(playercam, false);
			//}
		}
		//if (player->weapon) player->weapon->As<FPSWeapon>()->DetachFromPlayer(player);

		entity->SetHidden(false);
		player->weapon = As<FPSWeapon>();
		equipped = true;
		//entity->SetPosition(viewoffset);
		playerentity = player->GetEntity();

		auto model = entity->As<Model>();		
		if (model)
		{
			GetOut();
		}
	}
}

bool FPSWeapon::PlayerCanRun()
{
	return true;
}
