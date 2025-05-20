#pragma once
#include "Leadwerks.h"
#include "AmbientNoise.h"

using namespace Leadwerks;

AmbientNoise::AmbientNoise()
{ 
    name = "AmbientNoise";
}

void AmbientNoise::Start()
{
    if (sound and GetEnabled() and startplaying)
    {
        // This will give us a small delay so the listener will be positioned before sounds start playing
        timer = CreateTimer(1000);
        Listen(EVENT_TIMERTICK, timer);
    }
}

bool AmbientNoise::ProcessEvent(const Event& e)
{
    if (e.id == EVENT_TIMERTICK)
    {
        timer = NULL;
        Play();
    }
    return false;
}

void AmbientNoise::Update()
{
    if (not GetEnabled()) return;
    modulatedvolume = MoveTowards(modulatedvolume, targetvolume, 0.01f);
    if (speaker)
    {
        if (modulatedvolume == 0.0f)
        {
            speaker = NULL;
        }
        else
        {
            speaker->SetVolume(volume * modulatedvolume);
        }
    }
}

void AmbientNoise::FadeIn()
{
    targetvolume = 1;
}

void AmbientNoise::FadeOut()
{
    targetvolume = 0;
}

std::any AmbientNoise::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Play")
    {
        Play();
    }
    else if (name == "Stop")
    {
        Stop();
    }
    else if (name == "FadeOut")
    {
        FadeOut();
    }
    else if (name == "EndLoop")
    {
        EndLoop();
    }
    return BaseComponent::CallMethod(caller, name, args);
}

void AmbientNoise::EndLoop()
{
    if (speaker) speaker->SetLooping(false);
    speaker = NULL;
}

bool AmbientNoise::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    //if (properties["play"].is_boolean()) startplaying = properties["play"];
    if (properties["play"].is_boolean()) startplaying = properties["play"];
    if (properties["range"].is_number()) range = float(properties["range"]) / 100.0f;
    if (properties["volume"].is_number()) volume = float(properties["volume"]) / 100.0f;
    if (properties["pitch"].is_number()) pitch = float(properties["pitch"]) / 100.0f;
    if (properties["loop"].is_boolean()) loopmode = properties["loop"];
    if (properties["sound"].is_string())
    {
        sound = LoadSound(std::string(properties["sound"]));
    }
    else
    {
        sound = NULL;
    }

    auto r = BaseComponent::Load(properties, binstream, scene, flags, extra);
    return r;
}

void AmbientNoise::Stop()
{
    FadeOut();
    //if (speaker and speaker->GetState() == SPEAKER_PLAYING) speaker->Stop();
}

void AmbientNoise::Play()
{
    if (not sound) return;
    if (not GetEnabled()) return;

    targetvolume = 1.0f;
    if (not speaker) modulatedvolume = 1.0f;

    // If a looping sound is already being played, don't play it again
    if (loopmode and speaker and speaker->GetState() == SPEAKER_PLAYING)
    {
        speaker->SetVolume(volume * modulatedvolume);
        speaker->SetPitch(pitch);
        speaker->SetRange(range);
        return;
    }

    auto entity = GetEntity();
    speaker = entity->EmitSound(sound, range, volume, pitch, loopmode);
    if (not loopmode) speaker = NULL;

    FireOutputs("Play");
}

bool AmbientNoise::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["play"] = startplaying;
    properties["range"] = range * 100.0f;
    properties["volume"] = volume * 100.0f;
    properties["pitch"] = pitch * 100.0f;
    properties["loopmode"] = loopmode;
    if (sound) properties["sound"] = std::string(sound->path.ToUtf8String());
    return true;
}

//This method will work with simple components
shared_ptr<Component> AmbientNoise::Copy()
{
    return std::make_shared<AmbientNoise>(*this);
}