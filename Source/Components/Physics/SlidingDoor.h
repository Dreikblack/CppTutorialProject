#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;

class SlidingDoor : public Component
{
    shared_ptr<Joint> joint;
    Vec3 startposition;
    float storedmass = 0.0f;
    bool fullyopened = false;
    bool fullyclosed = false;

    void BuildJoint();
public: 
    bool openstate = false;
    Vec3 movement = Vec3(0, 2, 0);
    float speed = 1.0f;
    float maxforce = 1000;
    float distancetolerance = 0.1f;
    bool relativemovement = false;
    //bool togglemass = true;
    
    SlidingDoor();

    virtual void Start();
    virtual void Update();
    virtual void Open();
    virtual void Close();
    virtual void ToggleDoor();
    virtual void Disable();
    virtual void Enable();
    virtual void Toggle();
    virtual void Use(shared_ptr<Entity> user);
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
    virtual std::shared_ptr<Component> Copy();
};