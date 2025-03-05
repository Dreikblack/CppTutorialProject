#pragma once
#include "Leadwerks.h"
#include "CollisionTrigger.h"

using namespace Leadwerks;

CollisionTrigger::CollisionTrigger()
{ 
    name = "CollisionTrigger";
}

void CollisionTrigger::Start()
{
    auto entity = GetEntity();
    if (entity->GetCollisionType() == COLLISION_TRIGGER)
    {
        entity->SetRenderLayers(0);
        entity->SetShadows(false);
        entity->SetPickMode(PICK_NONE);
    }
}

void CollisionTrigger::Collide(shared_ptr<Entity> collidedentity, const Vec3& position, const Vec3& normal, const float speed)
{
    if (not enabled) return;
    FireOutputs("Collide"); 
    if (once) Disable();
}

void CollisionTrigger::Disable()
{
    enabled = false;
}

void CollisionTrigger::Enable()
{
    enabled = true;
}

bool CollisionTrigger::Load(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    auto entity = GetEntity();
    if (t["once"].is_boolean()) once = t["once"];
    if (t["enabled"].is_boolean()) enabled = t["enabled"];
	return true;
}

bool CollisionTrigger::Save(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
    t["once"] = once;
    t["enabled"] = enabled;
    return true;
}

std::any CollisionTrigger::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Enable")
    {
        Enable();
    }
    else if (name == "Disable")
    {
        Disable();
    }
    return false;
}

//This method will work with simple components
shared_ptr<Component> CollisionTrigger::Copy()
{
    return std::make_shared<CollisionTrigger>(*this);
}