#pragma once
#include "UltraEngine.h"
#include "Mover.h"

using namespace UltraEngine;

Mover::Mover()
{ 
    name = "Mover";
}

void Mover::Update()
{
    if (GetEnabled())
    {
        auto entity = GetEntity();
        if (globalcoords)
        {
            entity->Translate(movementspeed / 60.0f, true);
        }
        else
        {
            entity->Move(movementspeed / 60.0f);
        }
        entity->Turn(rotationspeed / 60.0f, globalcoords);
    }
}

bool Mover::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    if (properties["movementspeed"].is_array() and properties["movementspeed"].size() == 3)
    {            
        movementspeed.x = properties["movementspeed"][0];
        movementspeed.y = properties["movementspeed"][1];
        movementspeed.z = properties["movementspeed"][2];
    }
    if (properties["rotationspeed"].is_array() and properties["rotationspeed"].size() == 3)
    {            
        rotationspeed.x = properties["rotationspeed"][0];
        rotationspeed.y = properties["rotationspeed"][1];
        rotationspeed.z = properties["rotationspeed"][2];
    }
    if (properties["globalcoords"].is_boolean()) globalcoords = properties["globalcoords"];

    // The member "enabled" is located in the base component class.
    if (properties["enabled"].is_boolean()) enabled = properties["enabled"];
    return true;
}
	
bool Mover::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
    properties["movementspeed"] = {};
    properties["movementspeed"][0] = movementspeed.x;
    properties["movementspeed"][1] = movementspeed.y;
    properties["movementspeed"][2] = movementspeed.z;
    properties["rotationspeed"] = {};
    properties["rotationspeed"][0] = rotationspeed.x;
    properties["rotationspeed"][1] = rotationspeed.y;
    properties["rotationspeed"][2] = rotationspeed.z;
    properties["globalcoords"] = globalcoords;

    // The member "enabled" is located in the base component class.
    properties["enabled"] = enabled;
    return true;
}

//This method will work with simple components
shared_ptr<Component> Mover::Copy()
{
    return std::make_shared<Mover>(*this);
}
