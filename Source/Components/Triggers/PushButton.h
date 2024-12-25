#pragma once
#include "UltraEngine.h"
#include "../BaseComponent.h"

using namespace UltraEngine;

class PushButton : public BaseComponent
{
public: 
    bool enabled = true;

    PushButton();

    virtual void Enable();
    virtual void Disable();
    virtual bool GetEnabled();
    virtual void Use(shared_ptr<Entity> entity);
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
    virtual std::shared_ptr<Component> Copy();
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};