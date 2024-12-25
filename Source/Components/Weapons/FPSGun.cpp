#pragma once
#include "UltraEngine.h"
#include "../Player/Player.h"
#include "../Player/FPSPlayer.h"
#include "FPSGun.h"
#include "Projectile.h"

using namespace UltraEngine;

void FPSGun::AnimationDone(const UltraEngine::WString name, shared_ptr<UltraEngine::Object> object)
{
	auto wpn = object->As<FPSGun>();
	if (wpn)
	{
		//if (name == wpn->animations[ANIM_RELOAD])
		{
			wpn->reloading = false;
		}
	}
}

FPSGun::FPSGun()
{
	name = "FPSGun";
	viewmodelfov = 54.0f;
	//viewmodelcam = NULL;
	muzzle = NULL;
	//drawonlayer = false;
	//animations.fill("");
	//animations[ANIM_IDLE] = "idle";
	//animationmanger = NULL;
	reloading = false;
	automatic = false;
}

void FPSGun::DetachFromPlayer(std::shared_ptr<Component> playercomponent)
{
	FPSWeapon::DetachFromPlayer(playercomponent);
	if (muzzlelight) muzzlelight->SetHidden(true);
	if (muzzlesprite) muzzlesprite->SetHidden(true);
}

bool FPSGun::CanReload()
{
	if (ammo == 0) return false;
	if (puttingaway or getting) return false;
	if (reloading) return false;
	if (loadedammo >= clipsize) return false;
	if (GetFiring()) return false;
	return true;
}

bool FPSGun::ProcessEvent(const Event& e)
{
	if (not equipped) return true;
	switch (e.id)
	{
	case EVENT_MOUSEDOWN:
		if (e.data == MOUSE_LEFT)
		{
			if (CanFire())
			{
				if (loadedammo > 0)
				{
					Fire();
				}
				else
				{
					if (sound_empty) sound_empty->Play();
				}
			}
		}
		break;
	case EVENT_KEYDOWN:
		if (e.data == KEY_R)
		{
			if (reloading == false and not GetFiring())
			{
				//animationmanger->PlayAnimation(animations[ANIM_RELOAD]);
				Reload();
			}
		}
		break;
	}
	return true;
}

bool FPSGun::PlayerCanRun()
{
	if (puttingaway or getting or reloading) return false;
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (world and world->GetTime() < firetime) return false;
	return true;
}

bool FPSGun::CanFire()
{
	if (puttingaway or getting or reloading) return false;
	if (refirerate > 0)
	{
		auto entity = GetEntity();
		auto world = entity->GetWorld();
		if (world and world->GetTime() < firetime) return false;
	}
	return true;
}

void FPSGun::HideHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
	//Print("ReloadHook");
	auto gun = std::dynamic_pointer_cast<FPSGun>(extra);
	gun->puttingaway = false;
	auto nextweapon = gun->nextweapon.lock();
	if (nextweapon)
	{
		auto entity = gun->playerentity.lock();
		auto player = entity->GetComponent<Player>();
		gun->DetachFromPlayer(player);
		nextweapon->AttachToPlayer(player);
		gun->nextweapon.reset();
	}
}

void FPSGun::ReloadHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
	//Print("ReloadHook");
	auto gun = std::dynamic_pointer_cast<FPSGun>(extra);
	gun->reloading = false;
}

void FPSGun::Start()
{
	//Make sure this only gets called once, since some other components may call it early
	if (started) return;
	started = true;

	// Now find the model we'll be animating. It's possible that the model will be parented to a pivot.
	auto entity = GetEntity();	
	auto model = entity->As<Model>();
	if (not model) RuntimeError("FPSGun component must be attached to a model");

	muzzle = entity->FindChild("Muzzle", false);

	entity->SetShadows(false);

	int frame;
	int seq = model->FindAnimation("reload");
	if (seq != -1)
	{
		frame = model->CountAnimationFrames(seq);
		model->skeleton->AddHook(seq, frame, ReloadHook, Self());
	}

	seq = model->FindAnimation("hide");
	if (seq != -1)
	{
		frame = model->CountAnimationFrames(seq);
		model->skeleton->AddHook(seq, frame, HideHook, Self());
	}

	seq = model->FindAnimation("get");
	if (seq != -1)
	{
		frame = model->CountAnimationFrames(seq);
		model->skeleton->AddHook(seq, frame, GetHook, Self());
	}

	entity->SetHidden(true);

	auto world = entity->GetWorld();
	/*if (muzzle and world)
	{
		for (int n = 0; n < emitters.size(); ++n)
		{
			emitters[n] = CreateParticleEmitter(world, 6);
			emitters[n]->SetEmissionQuantity(6);
			emitters[n]->SetEmissionFrequency(800);
			emitters[n]->SetParticleRadius(0.2, 0.2);
			emitters[n]->SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0));
			emitters[n]->SetParticleRandomVelocity(0.15, 0.15, 0);
			emitters[n]->SetLooping(false);
			emitters[n]->SetMaterial(LoadMaterial("Materials/Effects/smoke.mat"));
			emitters[n]->Pause();
			emitters[n]->SetParent(muzzle, false);
		}
	}*/

	//Listen for events we will use
	Listen(EVENT_MOUSEDOWN, NULL);
	Listen(EVENT_KEYDOWN, NULL);

	FPSWeapon::Start();
}

bool FPSGun::GetFiring()
{
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (world and world->GetTime() < firetime) return true;
	return false;
}

void FPSGun::Update()
{
	UpdateBullets();

	if (not equipped) return;
	auto player = playerentity.lock();

	static bool moving = false;
	//static bool reloading = false;

	auto entity = GetEntity();
	auto model = entity->As<Model>();

	//Let's do this before movement...
	auto window = ActiveWindow();
	if (window)
	{
		if (loadedammo > 0 and automatic == true and window->MouseDown(MOUSE_LEFT) == true and CanFire())
		{
			Fire();
		}
	}

	if (reloading == false and GetFiring() == false and getting == false and puttingaway == false)
	{		
		if (player and player->GetAirborne())
		{
			model->Animate("idle");
		}
		else
		{
			auto velo = playerentity.lock()->GetVelocity().xz().Length();
			if (velo > 5.0f)
			{
				if (!playerentity.lock()->GetAirborne())
				{
					model->Animate("run");
					moving = true;
				}
			}
			else if (velo > 0.1)
			{
				model->Animate("walk");
				moving = false;
			}
			else
			{
				model->Animate("idle");
			}
		}
	}

	//Update muzzle flash
	UpdateMuzzleLight();
	if (muzzlelight)
	{
		auto world = entity->GetWorld();
		if (world->GetTime() > lastfiretime + muzzleflashduration)
		{ 
			muzzlelight->SetHidden(true);
			if (muzzlesprite) muzzlesprite->SetHidden(true);
		}
	}	
}

void FPSGun::UpdateBullets()
{
	if (bullets.empty()) return;
	auto it = bullets.begin();
	while (it != bullets.end())
	{
		auto entity = *it;
		for (auto c : entity->components)
		{
			auto projectile = c->As<Projectile>();
			if (projectile and projectile->GetExpired())
			{
				bullets.erase(it++);
				if (it == bullets.end()) return;
				break;
			}
		}
		++it;
	}
}
 
//This method will work with simple components
shared_ptr<Component> FPSGun::Copy()
{
	return std::make_shared<FPSGun>(*this);
}

bool FPSGun::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
	auto entity = GetEntity();

	if (properties["emptysound"].is_string())
	{
		sound_empty = LoadSound(std::string(properties["emptysound"]));
	}
	if (properties["reloadsound"].is_string()) sound_reload = LoadSound(std::string(properties["reloadsound"]));
	if (properties["firesound"].is_string()) sound_shoot = LoadSound(std::string(properties["firesound"]));

	if (properties["muzzleflashsize"].is_number()) muzzlespriteradius = properties["muzzleflashsize"];
	if (properties["inaccuracy"].is_number()) inaccuracy = properties["inaccuracy"];

	//if (properties["anim_idle"].is_string()) animations[ANIM_IDLE] = properties["anim_idle"];
	//if (properties["anim_fire"].is_string()) animations[ANIM_FIRE] = properties["anim_fire"];
	//if (properties["anim_reload"].is_string()) animations[ANIM_RELOAD] = properties["anim_reload"];
	//if (properties["anim_walk"].is_string()) animations[ANIM_WALK] = properties["anim_walk"];

	//if (properties["viewoffset"].is_array() and properties["viewoffset"].size() == 3)
//	{
	//	viewoffset[0] = properties["viewoffset"][0]; viewoffset[1] = properties["viewoffset"][1]; viewoffset[2] = properties["viewoffset"][2];
	//}

	if (properties["projectile"].is_string())
	{
		projectile = LoadPrefab(entity->GetWorld(), std::string(properties["projectile"]));
		if (projectile) projectile->SetHidden(true);
	}
	else
	{
		projectile = NULL;
	}

	auto world = entity->GetWorld();


	if (properties["automatic"].is_boolean()) automatic = properties["automatic"];

	if (properties["viewmodelfov"].is_number()) viewmodelfov = properties["viewmodelfov"];
	//if (properties["drawonlayer"].is_boolean()) drawonlayer = properties["drawonlayer"];

	//if (properties["index"].is_integer()) index = properties["index"];
	if (properties["automatic"].is_boolean()) automatic = properties["automatic"];

	return FPSWeapon::Load(properties, binstream, scene, flags, extra);
}

bool FPSGun::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
	properties["automatic"] = automatic;
	//properties["viewoffset"] = {};
	//properties["viewoffset"][0] = viewoffset.x; properties["viewoffset"][1] = viewoffset.y; properties["viewoffset"][2] = viewoffset.z;

	//properties["anim_idle"] = animations[ANIM_IDLE];
	//properties["anim_fire"] = animations[ANIM_FIRE];
	//properties["anim_reload"] = animations[ANIM_RELOAD];
	//properties["anim_walk"] = animations[ANIM_WALK];
	properties["inaccuracy"] = inaccuracy;
	properties["viewmodelfov"] = viewmodelfov;
	//properties["drawonlayer"] = drawonlayer;

	//properties["index"] = index;
	if (projectile)
	{
		auto prefab = projectile->GetPrefab();
		if (prefab) properties["projectile"] = prefab->path.ToUtf8String();
	}
	for (auto bullet : bullets)
	{
		if (bullet->GetHidden(false)) continue;
		if (not properties["bullets"].is_array()) properties["bullets"] = {};
		table t = {};
		//if (not bullet->Save(t, binstream, scene, flags, extra)) return false;
		properties["bullets"].push_back(t);
	}
	
	//if (not Gun::Save(properties, binstream, scene, flags, extra)) return false;
	return FPSWeapon::Save(properties, binstream, scene, flags, extra);
}

void FPSGun::Fire()
{
	--loadedammo;
	running = false;
	auto entity = GetEntity();
	if (not entity) return;
	auto model = entity->As<Model>();
	if (model) model->Animate("shoot", 1.0f, 0, ANIMATION_ONCE);
	auto world = entity->GetWorld();
	if (world)
	{
		lastfiretime = world->GetTime();
		firetime = lastfiretime + refirerate;
	}

	//Sprite
	if (muzzle)
	{
		if (not muzzlesprite)
		{
			muzzlesprite = CreateSprite(world, muzzlespriteradius, muzzlespriteradius);
			muzzlesprite->SetHandle(-muzzlespriteradius * 0.5f, -muzzlespriteradius * 0.5f);
			muzzlesprite->SetViewMode(SPRITEVIEW_DEFAULT);
			muzzlesprite->SetMaterial(LoadMaterial("Materials/Effects/muzzleflash.mat"));
			muzzlesprite->SetParent(muzzle);
			muzzlesprite->SetPosition(0, 0, 0);
		}
		muzzlesprite->SetRotation(0, 0, 0);
		muzzlesprite->Turn(0, 0, Random(360.0f));
		muzzlesprite->SetHidden(false);
	}

	if (not muzzlelight)
	{
		muzzlelight = CreatePointLight(world);
		muzzlelight->SetColor(1 * 2.0f, 0.9 * 2.0f, 0.6f * 2.0f);
		muzzlelight->SetShadows(false);
	}
	
	muzzlelight->SetHidden(false);
	if (sound_shoot)
	{
		//sound_shoot->Play();
		if (muzzle)
		{
			muzzle->EmitSound(sound_shoot);
		}
		else
		{
			entity->EmitSound(sound_shoot);
		}		
	}

	UpdateMuzzleLight();

	if (muzzle and projectile)
	{
		auto world = muzzle->GetWorld();
		auto bullet = projectile->Instantiate(world);
		bullet->SetHidden(false);
		bullet->SetColor(0, 1, 0, 1);
		bullet->SetPosition(muzzle->GetPosition(true), true);
		bullet->SetRotation(muzzle->GetRotation(true), true);
		bullet->Turn(0, 0, Random(360.0f));
		bullet->Turn(Random(-inaccuracy, inaccuracy), 0, 0);
		for (auto c : bullet->components)
		{
			auto projectile = c->As<Projectile>();
			if (projectile) projectile->owner = playerentity;
		}
		bullets.push_back(bullet);
	}

	/*emittercycle = (emittercycle + 1) % emitters.size();
	if (emitters[emittercycle])
	{
		emitters[emittercycle]->Reset();
		emitters[emittercycle]->Play();
		auto v = entity->GetVelocity();
		v = TransformNormal(v, NULL, entity) * v.Length();
		emitters[emittercycle]->SetParticleVelocity(v,false);
	}*/
}

void FPSGun::UpdateMuzzleLight()
{
	if (muzzlelight)
	{
		auto entity = GetEntity();		
		auto pp = playerentity.lock();
		auto player = pp->GetComponent<FPSPlayer>();
		auto pos = player->camera->GetPosition(true) + TransformNormal(0, -0.1, 1, player->camera, NULL) * 0.5f;
		muzzlelight->SetPosition(pos);
	}
}

bool FPSGun::GetReloading()
{
	return reloading;
}

void FPSGun::Reload()
{
	if (loadedammo >= clipsize) return;
	loadedammo += Min(ammo, clipsize - loadedammo);
	ammo = Max(0, ammo - clipsize);
	reloading = true;
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (world)
	{
		reloadtime = world->GetTime() + reloadspeed;
	}
	auto model = entity->As<Model>();
	model->Animate("reload", 1.0f, 250, ANIMATION_ONCE);
	if (sound_reload)
	{
		//sound_reload->Play();
		if (muzzle)
		{
			muzzle->EmitSound(sound_reload);
		}
		else
		{
			entity->EmitSound(sound_reload);
		}
	}
}

