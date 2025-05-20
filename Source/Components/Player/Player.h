#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class HealthManager;
class Player : public BaseComponent
{
protected:
	inline static std::list<std::weak_ptr<Player> > players;
	int health = 100;
	int team = 1;
public:

	virtual int GetTeam();
	virtual void Start();
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
	virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
	virtual void Damage(const int amount, shared_ptr<Entity> attacker);
	virtual int GetHealth();
};