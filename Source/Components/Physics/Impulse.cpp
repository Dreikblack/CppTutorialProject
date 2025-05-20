#pragma once
#include "Leadwerks.h"
#include "Impulse.h"

using namespace Leadwerks;

Impulse::Impulse()
{ 
    name = "Impulse";
}

void Impulse::Start()
{
    BaseComponent::Start();
}

void Impulse::Update()
{
    if (framecount > 0 and GetEnabled())
    {
        auto entity = GetEntity();
        if (force != 0.0f) entity->AddForce(force, globalcoords);
        if (torque != 0.0f) entity->AddTorque(torque, globalcoords);
        --framecount;
    }
}

bool Impulse::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["frames"].is_number()) framecount = properties["frames"];
    if (properties["global"].is_boolean()) globalcoords = properties["global"];
    if (properties["force"].is_array() and properties["force"].size() == 3)
    {
        force.x = properties["force"][0];
        force.y = properties["force"][1];
        force.z = properties["force"][2];
    }
    if (properties["torque"].is_array() and properties["torque"].size() == 3)
    {
        torque.x = properties["torque"][0];
        torque.y = properties["torque"][1];
        torque.z = properties["torque"][2];
    }
    return BaseComponent::Load(properties, binstream, scene, flags, extra);
}

bool Impulse::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["global"] = globalcoords;

    return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

//This method will work with simple components
shared_ptr<Component> Impulse::Copy()
{
    return std::make_shared<Impulse>(*this);
}
