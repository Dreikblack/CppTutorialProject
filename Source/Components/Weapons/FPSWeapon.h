#pragma once
#include "Leadwerks.h"
#include "../Player/FPSPlayer.h"

using namespace Leadwerks;

class FPSWeapon : public Component
{
protected:

    bool getting = false;
    bool puttingaway = false;
public:
    bool equipped = false;
    int refirerate = 100;
    uint64_t firetime = 0;
    std::weak_ptr<Entity> playerentity;
    std::weak_ptr<FPSWeapon> nextweapon;
    uint64_t lastfiretime = 0;
    float viewmodelfov;

    //virtual void Fire() = 0;
    //virtual void Reload() = 0;

    virtual bool PlayerCanRun();
    virtual void Start();
    virtual void PutAway();
    virtual void GetOut();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual void AttachToPlayer(std::shared_ptr<Component> player);
    virtual void DetachFromPlayer(std::shared_ptr<Component> player);
    static void GetHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
};