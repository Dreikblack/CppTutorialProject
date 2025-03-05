#pragma once
#include "Leadwerks.h"
#include "Enemy.h"

using namespace Leadwerks;

class Monster : public Enemy
{
    bool attackfinished = false;
public: 
    int attackanimation = 0;
    uint64_t meleeattacktime = 0;

    Monster();

    virtual void Start();
    virtual void Update();
    virtual void Collide(std::shared_ptr<Entity> collidedentity, const Vec3& position, const Vec3& normal, const float speed);
    virtual std::shared_ptr<Component> Copy();
    static void EndAttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};