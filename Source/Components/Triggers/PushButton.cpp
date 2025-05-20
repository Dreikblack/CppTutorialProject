#pragma once
#include "Leadwerks.h"
#include "PushButton.h"

using namespace Leadwerks;

PushButton::PushButton()
{ 
    name = "PushButton";
}

void PushButton::Enable()
{
    enabled = true;
}

void PushButton::Disable()
{
    enabled = false;
}

bool PushButton::GetEnabled()
{
    return enabled;
}

std::any PushButton::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Enable")
    {
        Enable();
    }
    else if (name == "Disable")
    {
        Disable();
    }
    return true;
}

void PushButton::Use(shared_ptr<Entity> entity)
{
    if (GetEnabled())
    {
        FireOutputs("Use");
        //if (sound) entity->EmitSound(sound);
    }
}

bool PushButton::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["enabled"].is_boolean()) enabled = properties["enabled"];
    return true;
}

bool PushButton::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["enabled"] = enabled;
    return true;
}

//This method will work with simple components
shared_ptr<Component> PushButton::Copy()
{
    return std::make_shared<PushButton>(*this);
}