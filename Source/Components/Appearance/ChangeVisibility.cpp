#pragma once
#include "Leadwerks.h"
#include "ChangeVisibility.h"

using namespace Leadwerks;

ChangeVisibility::ChangeVisibility()
{ 
    name = "ChangeVisibility";
}

void ChangeVisibility::Hide()
{
    auto entity = GetEntity();
    entity->SetHidden(true);
    FireOutputs("Hide");
}

void ChangeVisibility::Show()
{
    auto entity = GetEntity();
    entity->SetHidden(false);
    FireOutputs("Show");
}

std::any ChangeVisibility::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Hide")
    {
        Hide();
        return false;
    }
    else if (name == "Show")
    {
        Show();
        return false;
    }
    return BaseComponent::CallMethod(caller, name, args);
}

//This method will work with simple components
shared_ptr<Component> ChangeVisibility::Copy()
{
    return std::make_shared<ChangeVisibility>(*this);
}