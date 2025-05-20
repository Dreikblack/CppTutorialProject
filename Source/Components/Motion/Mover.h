#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class Mover : public BaseComponent
{
public: 
    Vec3 movementspeed;
    Vec3 rotationspeed;
    bool globalcoords {false};
    
    Mover();
    virtual void Update();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual std::shared_ptr<Component> Copy();
};