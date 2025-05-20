#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class Impulse : public BaseComponent
{
public: 
    Vec3 force;
    Vec3 torque;
    int framecount = 1;
    bool globalcoords = true;

    Impulse();

    virtual void Start();
    virtual void Update();
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
	virtual std::shared_ptr<Component> Copy();
};