#pragma once
#include "UltraEngine.h"
#include "../BaseComponent.h"

using namespace UltraEngine;

class SwingingDoor : public BaseComponent
{
    shared_ptr<Joint> joint;
    Vec3 startposition;
    float storedmass = 0.0f;
    bool fullyopened = false;
    bool fullyclosed = false;

    void BuildJoint();
public: 
    Vec3 offset = Vec3(0, 0, 0);
    Vec3 pin = Vec3(0, 1, 0);
    float distance = 90.0f;
    float movespeed = 60.0f;
    float maxforce = 60.0f;
    bool openstate = false;
    
    SwingingDoor();

    virtual void Use(shared_ptr<Entity> user);
    virtual void Start();
    virtual void Update();
    virtual void Open();
    virtual void Close();
    virtual void ToggleDoor();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
    virtual std::shared_ptr<Component> Copy();
};