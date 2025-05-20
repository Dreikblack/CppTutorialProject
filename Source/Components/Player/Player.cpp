#include "Leadwerks.h"
#include "Player.h"

using namespace Leadwerks;

void Player::Start()
{
    players.push_back(As<Player>());
}

bool Player::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    if (properties["health"].is_number()) health = properties["health"];
    if (properties["team"].is_number()) team = properties["team"];
    return BaseComponent::Load(properties, binstream, scene, flags, extra);
}

bool Player::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    properties["health"] = health;
    properties["team"] = team;
    return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

void Player::Damage(const int amount, shared_ptr<Entity> attacker)
{
    if (health <= 0) return;
    health -= amount;
    if (health <= 0)
    {
        auto entity = GetEntity();
        for (auto c : entity->components)
        {
            auto base = c->As<BaseComponent>();
            if (base) base->Kill(attacker);
        }
    }
}

int Player::GetTeam()
{
    return team;
}

int Player::GetHealth()
{
    return health;
}