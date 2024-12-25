#pragma once
#include "UltraEngine.h"
#include "Monster.h"

using namespace UltraEngine;

Monster::Monster()
{ 
    name = "Monster";
    team = 2;
}

void Monster::Start()
{
    auto entity = GetEntity();
    auto model = entity->As<Model>();
    if (model)
    {
        auto seq = model->FindAnimation("attack1");
        if (seq != -1)
        {
            int count = model->CountAnimationFrames(seq);
            model->skeleton->AddHook(seq, count - 1, EndAttackHook, Self());
        }
        seq = model->FindAnimation("attack2");
        if (seq != -1)
        {
            int count = model->CountAnimationFrames(seq);
            model->skeleton->AddHook(seq, count - 1, EndAttackHook, Self());
        }
    }
    Enemy::Start();
} 

void Monster::EndAttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
    auto monster = std::dynamic_pointer_cast<Monster>(extra);
    if (monster)
    {
        /*if (not monster->attackfinished)
        {
            monster->attackfinished = true;
            auto target = monster->target.lock();
            auto entity = monster->GetEntity();
            float attackrange = 2.5;
            if (entity->GetDistance(target) < attackrange)
            {
                for (auto c : target->components)
                {
                    auto base = c->As<BaseComponent>();
                    if (base) base->Damage(1, entity);
                }
            }
        }*/
        monster->attacking = false;
    }
}

void Monster::Update()
{
    if (not GetEnabled()) return;

    auto entity = GetEntity();    
    
    // Exit if dead
    for (auto c : entity->components)
    {
        auto player = c->As<Player>();
        if (player)
        {
            if (player->GetHealth() <= 0) return;
        }
    }
    
    auto model = entity->As<Model>();

    auto target = this->target.lock();

    // Stop attacking if target is dead
    if (target)
    {
        for (auto c : target->components)
        {
            auto player = c->As<Player>();
            if (player)
            {
                if (player->GetHealth() <= 0)
                {
                    target = NULL;
                    if (agent) agent->Stop();
                }
            }
        }
    }

    if (attacking == true and target != NULL)
    {
        float a = ATan(entity->matrix.t.x - target->matrix.t.x, entity->matrix.t.z - target->matrix.t.z);
        if (agent)
        {
            agent->SetRotation(a + 180);
        }
        if (not attackfinished)
        {
            auto world = entity->GetWorld();
            if (world)
            {
                if (world->GetTime() - meleeattacktime > 300)
                {
                    attackfinished = true;
                    auto entity = GetEntity();
                    float attackrange = 3.0f;
                    auto pos = entity->GetPosition(true);
                    auto dest = target->GetPosition(true) + target->GetVelocity();
                    if (pos.DistanceToPoint(dest) < attackrange)
                    //if (entity->GetDistance(target) < attackrange)
                    {
                        for (auto c : target->components)
                        {
                            auto base = c->As<BaseComponent>();
                            if (base) base->Damage(20, entity);
                        }
                    }
                }
            }
        }
        return;
    }
    
    //if (target and target->health <= 0) target = NULL;
    if (not target) ScanForTarget();
    if (target)
    {
        float d = entity->GetDistance(target);
        if (d > 3.0f)
        {
            if (agent) agent->Navigate(target->GetPosition(true));
            agent->SetMaxSpeed(6);
            if (model)
            {
                model->Animate("run");
            }
        }
        else
        {
            if (agent) agent->Stop();
            if (not attacking)
            {
                auto world = entity->GetWorld();
                if (world) meleeattacktime = world->GetTime();
                int index = Round(Random(1, 2));
                if (model) model->Animate("attack" + String(index), 1, 100, ANIMATION_ONCE);
                if (Round(Random(2)) == 0)
                {
                    index = Round(Random(0, 1));
                    if (sound_attack[index]) entity->EmitSound(sound_attack[index]);
                }
                attacking = true;
                attackfinished = false;
            }
            //if (model) model->Animate("idle");
        }
    }
    else
    {
        if (model) model->Animate("idle", 1.0, 250, ANIMATION_LOOP, Random(1000));
    }
}

void Monster::Collide(shared_ptr<Entity> collidedentity, const Vec3& position, const Vec3& normal, const float speed)
{
    
}

std::any Monster::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    if (name == "Enable")
    {
        Enable();
    }
    else if (name == "Disable")
    {
        Disable();
    }
    return false;
}

//This method will work with simple components
shared_ptr<Component> Monster::Copy()
{
    return std::make_shared<Monster>(*this);
}