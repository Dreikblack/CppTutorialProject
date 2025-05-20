#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"
#include "../Player/Player.h"

using namespace Leadwerks;

class Enemy : public Player
{
    uint64_t nextscanfortargettime = 0ull;
public:
    std::shared_ptr<Sound> sound_alert;
    std::array<std::shared_ptr<Sound>, 2> sound_attack;
    float eyeheight = 1.65f;
    float runspeed = 4;
    float walkspeed = 2;
    float scanrange = 100;
    float sensingrange = 2;
    std::weak_ptr<Entity> target;
    std::shared_ptr<NavAgent> agent;
    std::shared_ptr<NavMesh> navmesh;
    bool alive = true;
    bool attacking = false;

    virtual std::shared_ptr<Player> Enemy::GetEntityPlayer(shared_ptr<Entity> entity);
    virtual void Enable();
    virtual void Damage(const int health, shared_ptr<Entity> attacker);
    virtual void Kill(shared_ptr<Entity> killer);
    virtual void ScanForTarget();
    virtual void Start();
    virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
    static bool RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra);
};