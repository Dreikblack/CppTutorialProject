#pragma once
#include "Leadwerks.h"
#include "Projectile.h"

using namespace Leadwerks;

class Bullet : public Projectile
{
protected:
    float impactprefabalpha = 4.0f;
    std::vector<std::shared_ptr<Sound> > impactsounds;
    std::array<std::shared_ptr<ParticleEmitter>, 2> emitters;
    std::shared_ptr<Decal> decal;

public:
    float speed = 10;
    float radius = 0;
    int damage = 25;
    int impacttimeout = 3000;
    std::weak_ptr<Entity> owner;
    int updatecount = 0;

    Bullet();
    
    virtual void Start();
    virtual shared_ptr<Component> Copy();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual void Update();
};