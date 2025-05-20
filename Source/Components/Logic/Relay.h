#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class Relay : public BaseComponent
{
    uint64_t signaltime = 0;
public:
    float delay = 0.0f;
    bool once = false;
    bool fastrefiring = true;

    Relay();

    virtual void Update();
    virtual void Signal();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
    virtual std::shared_ptr<Component> Copy();
};

#if 0
class Relay : public BaseComponent
{
public: 
    int delay = 0;
    std::set<std::shared_ptr<Timer> > timers;

    Relay();

    virtual void Signal();
    virtual bool ProcessEvent(const Event& e);
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
    virtual std::shared_ptr<Component> Copy();
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};
#endif