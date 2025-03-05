#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace UltraEngine;

class Projectile : public BaseComponent
{
protected:
    bool hit = false;
    bool expired = false;
    static bool PickFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra);
public:
    std::weak_ptr<Entity> owner;
    virtual bool GetExpired();
};