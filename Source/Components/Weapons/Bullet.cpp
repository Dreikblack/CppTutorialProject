#pragma once
#include "Leadwerks.h"
#include "Bullet.h"

using namespace Leadwerks;

Bullet::Bullet()
{
	name = "Bullet";
}

void Bullet::Start()
{
	auto entity = GetEntity();
	entity->SetNavObstacle(false);
	entity->SetGravityMode(false);
	entity->SetMass(0);
	entity->SetCollisionType(COLLISION_NONE);
	entity->SetPickMode(PICK_NONE);

	auto world = entity->GetWorld();

	decal = CreateDecal(world);
	decal->SetMaterial(LoadMaterial("Materials/Decals/Bullet Holes/Concrete/bullethole_concrete.mat"));
	decal->SetScale(0.08f);

	emitters[0] = CreateParticleEmitter(world, 10);
	emitters[0]->SetEmissionQuantity(10);
	emitters[0]->SetEmissionFrequency(800);
	emitters[0]->SetParticleRadius(0.1, 0.5);
	emitters[0]->SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0));
	emitters[0]->SetParticleRandomVelocity(0.5, 0.5, 0.5);
	emitters[0]->SetLooping(false);
	emitters[0]->SetMaterial(LoadMaterial("Materials/Particles/smoke.mat"));
	emitters[0]->Pause();
	emitters[0]->SetHidden(true);

	// TODO - Ricochet debris particles
	/*
	emitters[1] = CreateParticleEmitter(world, 10);
	emitters[1]->SetEmissionQuantity(10);
	emitters[1]->SetEmissionFrequency(500);
	emitters[1]->SetParticleTurbulence(0);
	emitters[1]->SetParticleRadius(0.25, 0.25);
	emitters[1]->SetParticleColor(Vec4(1, 1, 1, 1), Vec4(1, 1, 1, 0));
	emitters[1]->SetParticleAcceleration(0, -9.8f, 0);
	emitters[1]->SetParticleRandomVelocity(3, 3, 3);
	emitters[1]->SetLooping(false);
	emitters[1]->SetMaterial(LoadMaterial("Materials/Particles/bulletfragments.mat"));
	emitters[1]->Pause();
	emitters[1]->SetHidden(true);
	*/
}

bool Bullet::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
	if (properties["damage"].is_number()) damage = properties["damage"];
	if (properties["speed"].is_number()) speed = properties["speed"];
	if (properties["radius"].is_number()) radius = properties["radius"];
	impactsounds.clear();
	for (int n = 0; n < 3; ++n)
	{
		std::string key = "impactsound" + String(n);
		if (properties[key].is_string())
		{
			std::string impactsoundpath = std::string(properties[key]);
			if (not impactsoundpath.empty())
			{
				auto sound = LoadSound(impactsoundpath);
				if (sound) impactsounds.push_back(sound);
			}
		}
	}
	return true;
}

bool Bullet::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
	properties["speed"] = speed;
	properties["radius"] = radius;
	properties["damage"] = damage;
	return true;
}

//This method will work with simple components
shared_ptr<Component> Bullet::Copy()
{
	auto bullet = std::make_shared<Bullet>(*this);
	bullet->impactsounds = impactsounds;
	return bullet;
}

void Bullet::Update()
{
	auto entity = GetEntity();

	if (hit and not expired)
	{
		expired = true;
		if (decal and not decal->GetHidden(false))
		{
			impactprefabalpha -= 0.005f;
			auto color = decal->GetColor();
			color.a = Min(impactprefabalpha, 1.0f);
			decal->SetColor(color);
			if (impactprefabalpha <= 0.0f)
			{
				decal->SetHidden(true);
				decal->SetParent(NULL);
			}
			else
			{
				expired = false;
			}
		}
	}
	if (expired)
	{
		return;
	}

	if (not GetEnabled()) return;
	if (entity->GetHidden()) return;

	auto world = entity->GetWorld();
	if (not world) return;

	auto pos = entity->GetPosition(true);
	auto nextpos = pos + TransformNormal(0, 0, 1, entity, NULL) * speed / 60.0f;
	
	auto player = owner.lock();
	auto pickinfo = world->Pick(pos, nextpos, 0.0f, true, PickFilter, player);
	if (pickinfo.entity)
	{
		if (pickinfo.entity->GetMass() > 0.0f)
		{
			float force = 20.0;
			pickinfo.entity->AddPointForce((nextpos - pos).Normalize() * force, pickinfo.position);
		}

		for (auto c : pickinfo.entity->components)
		{
			auto base = c->As<BaseComponent>();
			if (base) base->Damage(damage, entity);
		}

		hit = true;
		entity->SetPosition(pickinfo.position);
		entity->SetHidden(true);
		if (decal)
		{
			//Bullet hole decal
			decal->SetPosition(pickinfo.position, true);
			auto scale = decal->scale;
			scale /= TransformVector(1, 0, 0, NULL, pickinfo.entity).Length();
			decal->SetParent(pickinfo.entity);
			decal->SetScale(scale);
			decal->SetHidden(false);
			decal->AlignToVector(pickinfo.normal);
			decal->Turn(0.0f, 0.0f, Random(360.0f));

			//Smoke particles
			emitters[0]->SetPosition(pickinfo.position);
			emitters[0]->SetParticleVelocity(pickinfo.normal);
			emitters[0]->SetHidden(false);
			emitters[0]->Play();
			/*
			emitters[1]->SetPosition(pickinfo.position);
			emitters[1]->SetParticleVelocity(pickinfo.normal * 4.0f);
			emitters[1]->SetHidden(false);
			emitters[1]->Play();
			*/
		}
		Disable();
		if (not impactsounds.empty())
		{
			int index = Random(0, int(impactsounds.size() - 1));
			entity->EmitSound(impactsounds[index]);
		}
	}
	else
	{
		entity->SetPosition(nextpos);
	}
}
