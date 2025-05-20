#pragma once
#include "Leadwerks.h"

using namespace Leadwerks;

class ParticleEffect : public Component {
protected:
	bool isTemporary;
	int initDuration;
	int durationLeft;
	Vec3 initVelocity;
	float initTurbolence;
	uint64_t lastMsTime = 0;
	shared_ptr<Entity> holdedEntity;
public:
	bool reduceEffectWithTime;
	ParticleEffect();
	~ParticleEffect() override;
	std::shared_ptr<Component> Copy() override;
	bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	void Start() override;
	void Update() override;
};