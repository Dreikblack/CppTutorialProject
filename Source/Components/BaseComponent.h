#pragma once
#include "Leadwerks.h"

using namespace Leadwerks;

class BaseComponent : public Component
{
public:
	virtual void Damage(const int amount, shared_ptr<Entity> attacker);
	virtual void Kill(shared_ptr<Entity> attacker);
	virtual void Use(shared_ptr<Entity> user);
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
	virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
	virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};