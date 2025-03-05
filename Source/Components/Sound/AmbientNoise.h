#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class AmbientNoise : public BaseComponent
{
public: 
    float pitch = 1.0f;
    float volume = 1.0;
    float range = 10.0f;
    bool loopmode = true;
    std::shared_ptr<Speaker> speaker;
    std::shared_ptr<Sound> sound;
    shared_ptr<Timer> timer;
    float modulatedvolume = 1.0f;
    float targetvolume = 1.0f;
    bool startplaying = true;

    AmbientNoise();

    virtual void Start();
    virtual void Update();
    virtual shared_ptr<Component> Copy();
    virtual void Play();
    virtual void Stop();
    virtual void FadeOut();
    virtual void EndLoop();
    virtual void FadeIn();
    virtual bool ProcessEvent(const Event& e);
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};
