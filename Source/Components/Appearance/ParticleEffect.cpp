#pragma once
#include "Leadwerks.h"
#include "ParticleEffect.h"

using namespace UltraEngine;

ParticleEffect::ParticleEffect() {
	name = "ParticleEffect";
	isTemporary = true;
	reduceEffectWithTime = false;
	durationLeft = 500;
}

ParticleEffect::~ParticleEffect() = default;

shared_ptr<Component> ParticleEffect::Copy() {
	return std::make_shared<ParticleEffect>(*this);
}

bool ParticleEffect::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	if (properties["isTemporary"].is_boolean()) {
		isTemporary = properties["isTemporary"];
	}
	if (properties["duration"].is_number()) {
		initDuration = properties["duration"];
	}
	if (properties["durationLeft"].is_number()) {
		durationLeft = properties["durationLeft"];
	} else {
		durationLeft = initDuration;
	}
	if (properties["reduceEffectWithTime"].is_boolean()) {
		reduceEffectWithTime = properties["reduceEffectWithTime"];
	}
	return true;
}

bool ParticleEffect::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	properties["isTemporary"] = isTemporary;
	properties["durationLeft"] = durationLeft;
	properties["duration"] = initDuration;
	properties["reduceEffectWithTime"] = reduceEffectWithTime;

	return true;
}

void ParticleEffect::Start() {
	auto entity = GetEntity();
	if (isTemporary && entity) {
		holdedEntity = entity;
		lastMsTime = holdedEntity->GetWorld()->GetTime();
		auto emitter = holdedEntity->As<ParticleEmitter>();
		if (emitter) {
			initVelocity = emitter->GetParticleVelocity();
			initTurbolence = emitter->GetParticleTurbulence();
		}
	}
}

void ParticleEffect::Update() {
	if (isTemporary && holdedEntity && holdedEntity->GetWorld() && !holdedEntity->GetHidden()) {
		auto entity = GetEntity();
		auto now = holdedEntity->GetWorld()->GetTime();
		int deltaTime = now - lastMsTime;
		durationLeft = MoveTowards((float)durationLeft, 0, deltaTime);
		lastMsTime = now;
		if (durationLeft == 0 && holdedEntity) {
			holdedEntity->SetParent(nullptr);
			holdedEntity = nullptr;
		} else if (reduceEffectWithTime && durationLeft > 0 && holdedEntity) {
			auto emitter = holdedEntity->As<ParticleEmitter>();
			float coeff = initDuration > 0 ? ((float)durationLeft / (float)initDuration) : 1;
			emitter->SetParticleVelocity(initVelocity * coeff);
			emitter->SetParticleTurbulence(initTurbolence * coeff);
		}
	}
}


