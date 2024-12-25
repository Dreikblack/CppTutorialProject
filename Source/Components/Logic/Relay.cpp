#pragma once
#include "UltraEngine.h"
#include "Relay.h"

using namespace UltraEngine;

Relay::Relay()
{
    name = "Relay";
}

void Relay::Update()
{
    if (signaltime > 0)
    {
        auto now = GetEntity()->GetWorld()->GetTime();
        if (now > signaltime + (delay * (float)1000))
        {
            Signal();
        }
    }
}

void Relay::Signal()
{
    if (not GetEnabled()) return;
    FireOutputs("Signal");
    signaltime = 0;
    if (once) Disable();
}

bool Relay::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
    if (properties["delay"].is_number()) delay = properties["delay"];
    if (properties["once"].is_boolean()) once = properties["once"];
    if (properties["fastrefiring"].is_boolean()) fastrefiring = properties["fastrefiring"];

    return BaseComponent::Load(properties, binstream, scene, flags, extra);;
}

bool Relay::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
    properties["delay"] = delay;
    properties["once"] = once;
    properties["fastrefiring"] = fastrefiring;

    return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

std::any Relay::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Signal")
    {
        if (delay <= 0.0f)
        {
            Signal();
        }
        else
        {
            // If fastretrigger isn't enabled and we have a pending output, abort the new output.
            // This allows for the switch to finish what it's doing before processing any new inputs.
            if (not fastrefiring and signaltime != 0) return false;

            signaltime = GetEntity()->GetWorld()->GetTime();
        }
    }
    return BaseComponent::CallMethod(caller, name, args);
}

//This method will work with simple components
shared_ptr<Component> Relay::Copy()
{
    return std::make_shared<Relay>(*this);
}

#if 0
Relay::Relay()
{ 
    name = "Relay";
}

bool Relay::ProcessEvent(const Event& e)
{
    if (e.id == EVENT_TIMERTICK)
    {
        auto timer = e.source->As<Timer>();
        auto it = timers.find(timer);
        if (it != timers.end())
        {
            timer->Stop();
            timers.erase(it);
            FireOutputs("Signal");
            return false;
        }
    }
    return true;
}

bool Relay::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["delay"].is_number()) delay = properties["delay"];
    return true;
}

bool Relay::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["delay"] = delay;
    return true;
}

void Relay::Signal()
{
    if (delay == 0)
    {
        FireOutputs("Signal");
    }
    else
    {
        auto timer = CreateTimer(delay);
        Listen(EVENT_TIMERTICK, timer);
        timers.insert(timer);
    }
}

std::any Relay::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Signal")
    {
        Signal();
    }
    return BaseComponent::CallMethod(caller, name, args);
}

//This method will work with simple components
shared_ptr<Component> Relay::Copy()
{
    return std::make_shared<Relay>(*this);
}
#endif