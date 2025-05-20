#include "Leadwerks.h"
#include "Enemy.h"

void Enemy::Start()
{
    auto entity = GetEntity();
    auto model = entity->As<Model>();
    if (navmesh)
    {
        agent = CreateNavAgent(navmesh, 0.5, 1.8);
        agent->SetPosition(entity->GetPosition(true));
        agent->SetRotation(entity->GetRotation(true).y);
        entity->SetPosition(0, 0, 0);
        entity->SetRotation(0, 180, 0);
        entity->Attach(agent);
    }
    entity->SetNavObstacle(false);
    entity->SetCollisionType(COLLISION_PLAYER);
    entity->SetMass(0);
    entity->SetPhysicsMode(PHYSICS_RIGIDBODY);
    Player::Start();
}

void Enemy::Enable()
{
    BaseComponent::Enable();
    if (sound_alert)
    {
        auto target = this->target.lock();
        if (target)
        {
            auto entity = GetEntity();
            entity->EmitSound(sound_alert, 50);
        }
    }
}

void Enemy::Damage(const int amount, shared_ptr<Entity> attacker)
{
    Player::Damage(amount, attacker);
    if (GetHealth() <= 0) return;
    auto entity = GetEntity();
    if (target.lock() == NULL and attacker != entity) target = attacker;// Make him angry if someone hurts him!    
}

void Enemy::Kill(shared_ptr<Entity> killer)
{
    if (not alive) return;
    auto entity = GetEntity();
    auto model = entity->As<Model>();
    alive = false;
    if (model) model->Animate("death", 1, 250, ANIMATION_ONCE);
    if (agent) agent->Stop();
    entity->Detach();
    agent = NULL;
    entity->SetCollisionType(COLLISION_NONE);
    entity->SetPickMode(PICK_NONE);
}

bool Enemy::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["alertsound"].is_string())
    {
        sound_alert = LoadSound(std::string(properties["alertsound"]));
    }
    for (int n = 0; n < 2; ++n)
    {
        std::string key = "attacksound" + String(n + 1);
        if (properties[key].is_string())
        {
            sound_attack[n] = LoadSound(std::string(properties[key]));
        }
    }
    if (properties["runspeed"].is_number()) runspeed = properties["runspeed"];
    if (properties["walkspeed"].is_number()) walkspeed = properties["walkspeed"];
    target.reset();
    if (properties["target"].is_string())
    {
        target = scene->GetEntity(std::string(properties["target"]));
    }
    navmesh = NULL;
    if (not scene->navmeshes.empty()) navmesh = scene->navmeshes[0];
    return BaseComponent::Load(properties, binstream, scene, flags, extra);;
}

bool Enemy::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["runspeed"] = runspeed;
    properties["walkspeed"] = walkspeed;
    auto target = this->target.lock();
    if (target) properties["target"] = std::string(target->GetUuid());

    return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

bool Enemy::RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra)
{
    if (entity == extra) return false;
    auto type = entity->GetCollisionType();
    return (type == COLLISION_SCENE or type == COLLISION_PROP);
}

std::shared_ptr<Player> Enemy::GetEntityPlayer(shared_ptr<Entity> entity)
{
    for (auto c : entity->components)
    {
        auto player = c->As<Player>();
        if (player) return player;
    }
}

void Enemy::ScanForTarget()
{
    auto entity = GetEntity();
    auto world = entity->GetWorld();
    if (world)
    {
        // We only want to perform this about twice each second, staggering the operation between different entities
        auto now = world->GetTime();
        if (now < nextscanfortargettime) return;
        nextscanfortargettime = now + Random(100, 200);

        auto temp = entity->GetPickMode();
        entity->SetPickMode(PICK_NONE);
        //auto entities = world->GetTaggedEntities("player");
        Vec3 pos;
        float dist;
        for (auto wptr : players)
        {
            auto player = wptr.lock();
            if (not player) continue;
            if (player == Self()) continue;
            if (player->GetHealth() <= 0) continue;
            if (player->GetTeam() == GetTeam()) continue;
            auto e = player->GetEntity();
            if (not e) continue;
            dist = e->GetDistance(entity);
            if (dist > scanrange) continue;
            /*if (dist > sensingrange)
            {
                pos = TransformPoint(e->GetPosition(true), NULL, entity);
                if (pos.z < 0.0f) continue;
            }*/
            auto temp2 = e->GetPickMode();
            e->SetPickMode(PICK_NONE);
            auto pick = world->Pick(entity->GetPosition(true) + Vec3(0, eyeheight, 0), e->GetBounds(BOUNDS_RECURSIVE).center, 0, true, RayFilter, entity);
            e->SetPickMode(temp2);
            if (not pick.entity)
            {
                target = e;
                if (sound_alert) entity->EmitSound(sound_alert, 50);
                break;
            }
        }
        entity->SetPickMode(temp);
    }
}
