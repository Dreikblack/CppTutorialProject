#include "Leadwerks.h"
#include "SlidingDoor.h"

using namespace Leadwerks;

SlidingDoor::SlidingDoor()
{ 
    name = "SlidingDoor";
}

void SlidingDoor::Use(shared_ptr<Entity> user)
{
    if (enabled)
    {
        if (openstate)
        {
            Close();
        }
        else
        {
            Open();
        }
    }
}

void SlidingDoor::BuildJoint()
{
    if (not joint)
    {
        auto entity = GetEntity();
        storedmass = entity->GetMass();
        if (storedmass == 0.0f)
        {
            storedmass = 10;
            entity->SetMass(storedmass);
        }
        startposition = entity->GetPosition(true);
        auto parent = entity->GetParent();
        if (not parent or parent->GetMass() == 0.0f) entity->SetGravityMode(false);

        if (relativemovement)
        {
            movement = TransformVector(movement.x, movement.y, movement.z, entity, NULL);
        }

        joint = CreateSliderJoint(startposition, movement.Normalize(), parent, entity);
        joint->SetMotorSpeed(speed);
        joint->SetMaxForce(maxforce);

        // TODO: Find a way to "teleport" to where it needs to be!
        //Josh: If it's open, it should already be positioned in the open state, no need to move it
        //if (openstate) 
        //    joint->SetPose(movement.Length());
        //else
        entity->SetMass(0);
    }
}

void SlidingDoor::Start()
{
    BuildJoint();
}

void SlidingDoor::Update()
{
    auto entity = GetEntity();
    if (entity->GetMass() > 0)
    {
        auto offset = Abs(joint->GetOffset());
        if (openstate)
        {
            if (offset != 0.0f)
            {
                auto dis = Abs(offset - movement.Length());
                if (dis == 0.0f) return;
                if (dis < 0.01)
                {
                    if (!fullyopened)
                    {
                        FireOutputs("FullyOpened");
                        entity->SetMass(0);
                        fullyopened = true;
                        
                    }
                }
            }
        }
        else
        {
            if (offset != 0.0f)
            {
                if (offset < 0.01)
                {
                    if (!fullyclosed)
                    {
                        Print("Fully Closed");
                        FireOutputs("FullyClosed");
                        entity->SetMass(0);
                        //if (not relativemovement) entity->SetPosition(startposition);
                        fullyclosed = true;

                    }
                }
            }
        }
    }
}

void SlidingDoor::Open()
{
    if (openstate) return;
    if (not GetEnabled())
    {
        Print("Can't open disabled door");
        return;
    }
    auto entity = GetEntity();
    entity->SetMass(storedmass);
    fullyopened = false;
    fullyclosed = false;
    openstate = true;
    joint->SetPose(movement.Length());
    FireOutputs("Open");
}

void SlidingDoor::Close()
{
    if (not openstate) return;
    if (not GetEnabled()) return;
    auto entity = GetEntity();
    entity->SetMass(storedmass);
    fullyopened = false;
    fullyclosed = false;
    openstate = false;
    joint->SetPose(0);
    FireOutputs("Close");
}

void SlidingDoor::ToggleDoor()
{
    if (GetEnabled())
    {
        if (not openstate)
            Open();
        else
            Close();

        FireOutputs("ToggleDoor");
    }
}

void SlidingDoor::Disable()
{
    enabled = false;
    FireOutputs("Disable");
}

void SlidingDoor::Enable()
{
    enabled = true;
    FireOutputs("Enable");
}

void SlidingDoor::Toggle()
{
    enabled = !enabled;
    FireOutputs("Toggle");
}

bool SlidingDoor::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    if (properties["relativemovement"].is_boolean()) relativemovement = properties["relativemovement"];
    if (properties["speed"].is_number()) speed = properties["speed"];
    if (properties["maxforce"].is_number()) maxforce = properties["maxforce"];

    if (properties["movement"].is_array() and properties["movement"].size() == 3)
    {
        movement.x = float(properties["movement"][0]) / 100.0f;
        movement.y = float(properties["movement"][1]) / 100.0f;
        movement.z = float(properties["movement"][2]) / 100.0f;
    }

    if (properties["startposition"].is_array() and properties["startposition"].size() == 3)
    {
        auto entity = GetEntity();
        startposition.x = properties["startposition"][0];
        startposition.y = properties["startposition"][1];
        startposition.z = properties["startposition"][2];
        auto temp = entity->GetPosition(true);
        BuildJoint();
        entity->SetPosition(temp, true);
    }

    if (properties["openstate"].is_boolean())
    {
        openstate = properties["openstate"];
        if (joint)
        {
            if (openstate)
            {
                Open();
            }
            else
            {
                Close();
            }
        }
    }

    // In most cases, we can disable the mass to prevent unwanted physics interaction when
    // the door is in it's resting state. However, for things such as lifts, it's probably
    // best to use disable this flag and rely on a high maxforce value instead.
    //if (properties["togglemass"].is_boolean()) togglemass = properties["togglemass"];

    // The member "enabled" is located in the base component class.
    if (properties["enabled"].is_boolean()) enabled = properties["enabled"];
    return true;
}

bool SlidingDoor::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
    properties["movement"] = {};
    properties["movement"][0] = movement.x * 100.0f;
    properties["movement"][1] = movement.y * 100.0f;
    properties["movement"][2] = movement.z * 100.0f;
    properties["speed"] = speed;
    properties["openstate"] = openstate;
    properties["startposition"] = {};
    properties["startposition"][0] = startposition.x;
    properties["startposition"][1] = startposition.y;
    properties["startposition"][2] = startposition.z;
    properties["maxforce"] = maxforce;
    properties["relativemovement"] = relativemovement;
    //properties["togglemass"] = togglemass;

    // The member "enabled" is located in the base component class.
    properties["enabled"] = enabled;
    return true;
}

std::any SlidingDoor::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Enable")
    {
        Enable();
    }
    else if (name == "Disable")
    {
        Disable();
    }
    else if (name == "Toggle")
    {
        Toggle();
    }
    else if (name == "Open")
    {
        Open();
    }
    else if (name == "Close")
    {
        Close();
    }
    else if (name == "ToggleDoor")
    {
        ToggleDoor();
    }

    return false;
}

//This method will work with simple components
shared_ptr<Component> SlidingDoor::Copy()
{
    return std::make_shared<SlidingDoor>(*this);
}