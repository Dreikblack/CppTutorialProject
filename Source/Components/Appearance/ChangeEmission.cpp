#pragma once
#include "Leadwerks.h"
#include "ChangeEmission.h"

using namespace Leadwerks;

ChangeEmission::ChangeEmission()
{ 
    name = "ChangeEmission";
}

bool ChangeEmission::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["color1"].is_array() and properties["color1"].size() >= 3)
    {
        color0.r = properties["color1"][0];
        color0.g = properties["color1"][1];
        color0.b = properties["color1"][2];
    }
    if (properties["color2"].is_array() and properties["color2"].size() >= 3)
    {
        color1.r = properties["color2"][0];
        color1.g = properties["color2"][1];
        color1.b = properties["color2"][2];
    }
    if (properties["color3"].is_array() and properties["color3"].size() >= 3)
    {
        color2.r = properties["color3"][0];
        color2.g = properties["color3"][1];
        color2.b = properties["color3"][2];
    }
    if (properties["recursive"].is_boolean()) recursive = properties["recursive"];
    return true;
}

bool ChangeEmission::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["color1"] = {};
    properties["color1"][0] = color0.r;
    properties["color1"][1] = color0.g;
    properties["color1"][2] = color0.b;

    properties["color2"] = {};
    properties["color2"][0] = color1.r;
    properties["color2"][1] = color1.g;
    properties["color2"][2] = color1.b;

    properties["color3"] = {};
    properties["color3"][0] = color2.r;
    properties["color3"][1] = color2.g;
    properties["color3"][2] = color2.b;

    return true;
}

std::any ChangeEmission::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    auto entity = GetEntity();
    if (GetEnabled())
    {
        if (name == "SetColor1")
        {
            entity->SetEmissionColor(color0.r, color0.g, color0.b, recursive);
            return false;
        }
        else if (name == "SetColor2")
        {
            entity->SetEmissionColor(color1.r, color1.g, color1.b, recursive);
            return false;
        }
        else if (name == "SetColor3")
        {
            entity->SetEmissionColor(color2.r, color2.g, color2.b, recursive);
            return false;
        }
    }
    return BaseComponent::CallMethod(caller, name, args);
}

//This method will work with simple components
shared_ptr<Component> ChangeEmission::Copy()
{
    return std::make_shared<ChangeEmission>(*this);
}