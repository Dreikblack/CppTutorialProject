#include "Leadwerks.h"
#include "SwingingDoor.h"

using namespace Leadwerks;

SwingingDoor::SwingingDoor()
{ 
    name = "SwingingDoor";
}

void SwingingDoor::BuildJoint()
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

        auto position = entity->GetPosition() + offset;
        auto translate = TransformNormal(pin.x, pin.y, pin.z, entity, NULL);
        joint = CreateHingeJoint(position, translate, entity->GetParent(), entity);
        joint->SetMaxTorque(0.0f);
        joint->SetMotorSpeed(movespeed);

        // TODO: Find a way to "teleport" to where it needs to be!
        //Josh: If it's open, it should already be positioned in the open state, no need to move it
        /*if (openstate)
        {
            //joint->SetMotorSpeed(500);
            joint->SetPose(distance);
            //joint->SetMotorSpeed(movespeed);
        }
        else*/
        //entity->SetMass(0);
    }
}

void SwingingDoor::Start()
{
    auto entity = GetEntity();
    storedmass = entity->GetMass();
    if (storedmass == 0.0f) storedmass = 10.0f;
    entity->SetMass(0);
}

void SwingingDoor::Update()
{
    auto entity = GetEntity();
    if (entity->GetMass() > 0)
    {
        auto o = Abs(joint->GetOffset());
        if (openstate)
        {
            if (o != 0.0f)
            {
                auto dis = Abs(o - distance);
                if (dis == 0.0f) return;
                if (dis < 0.01)
                {
                    if (!fullyopened)
                    {
                        FireOutputs("FullyOpened");
                        joint->SetMaxTorque(0);
                        entity->SetMass(0);
                        fullyopened = true;
                    }
                }
            }
        }
        else
        {
            if (o != 0.0f)
            {
                if (o < 0.01)
                {
                    if (!fullyclosed)
                    {
#ifdef _DEBUG
                        Print("Fully Closed");
#endif
                        FireOutputs("FullyClosed");
                        entity->SetMass(0);
                        joint->SetMaxTorque(0);
                        fullyclosed = true;
                    }
                }
            }
        }
    }
}

void SwingingDoor::Open()
{
    if (openstate) return;
    if (not GetEnabled()) return;
    auto entity = GetEntity();
    entity->SetMass(storedmass);
    if (not joint) BuildJoint();
    fullyopened = false;
    fullyclosed = false;
    openstate = true;
    auto pos = entity->position;
    //entity->SetPosition(pos + Vec3(1, 0, 0));// Triggers light refreshing early
    //entity->SetPosition(pos);
    joint->SetMaxTorque(maxforce);
    joint->SetPose(distance);
    //joint->SetPose(distance);
    FireOutputs("Open");
}

void SwingingDoor::Close()
{
    if (not openstate) return;
    if (not GetEnabled()) return;
    auto entity = GetEntity();
    entity->SetMass(storedmass);
    if (not joint) BuildJoint();
    fullyopened = false;
    fullyclosed = false;
    openstate = false;
    //joint->SetPose(0);
    auto pos = entity->position;
    joint->SetMaxTorque(maxforce);
    joint->SetPose(0);
    //entity->SetPosition(pos + Vec3(1, 0, 0));// Triggers light refreshing early
    //entity->SetPosition(pos);
    FireOutputs("Close");
}

void SwingingDoor::ToggleDoor()
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

void SwingingDoor::Use(shared_ptr<Entity> user)
{
    if (GetEnabled())
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

bool SwingingDoor::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    if (properties["distance"].is_number()) distance = properties["distance"];

    if (properties["offset"].is_array() and properties["offset"].size() == 3)
    {
        offset.x = properties["offset"][0];
        offset.y = properties["offset"][1];
        offset.z = properties["offset"][2];
    }

    if (properties["pin"].is_array() and properties["pin"].size() == 3)
    {
        pin.x = properties["pin"][0];
        pin.y = properties["pin"][1];
        pin.z = properties["pin"][2];
    }

    if (properties["integervalue"].is_number()) distance = properties["distance"];
    if (properties["movespeed"].is_number()) movespeed = properties["movespeed"];
    if (properties["maxforce"].is_number()) maxforce = properties["maxforce"];

    if (properties["startposition"].is_array() and properties["startposition"].size() == 3)
    {
        auto entity = GetEntity();
        startposition.x = properties["startposition"][0];
        startposition.y = properties["startposition"][1];
        startposition.z = properties["startposition"][2];
        //auto temp = entity->GetQuaternion(true);
        BuildJoint();
        //entity->SetRotation(temp, true);
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
  
    return BaseComponent::Load(properties, binstream, scene, flags, extra);
}

bool SwingingDoor::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
    properties["distance"] = distance;

    properties["offset"] = {};
    properties["offset"][0] = offset.x;
    properties["offset"][1] = offset.y;
    properties["offset"][2] = offset.z;

    properties["pin"] = {};
    properties["pin"][0] = pin.x;
    properties["pin"][1] = pin.y;
    properties["pin"][2] = pin.z;

    properties["distance"] = distance;
    properties["movespeed"] = movespeed;
    properties["maxforce"] = maxforce;
    properties["openstate"] = openstate;

    properties["startposition"] = {};
    properties["startposition"][0] = startposition.x;
    properties["startposition"][1] = startposition.y;
    properties["startposition"][2] = startposition.z;

    // The member "enabled" is located in the base component class.
    return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

std::any SwingingDoor::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Open")
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
    return BaseComponent::CallMethod(caller, name, args);
}

//This method will work with simple components
shared_ptr<Component> SwingingDoor::Copy()
{
    return std::make_shared<SwingingDoor>(*this);
}