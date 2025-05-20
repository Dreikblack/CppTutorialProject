#pragma once
#include "Leadwerks.h"
#include "FPSWeapon.h"

using namespace Leadwerks;

class FPSGun : public FPSWeapon
{
    shared_ptr<Entity> projectile;
    std::list<shared_ptr<Entity> > bullets;
    shared_ptr<Entity> muzzle;
    shared_ptr<Light> muzzlelight;
    int muzzleflashduration = Ceil(16.66667f * 2.0f);// stay onscreen for two frames
    //shared_ptr<Camera> viewmodelcam;
    bool reloading = false;
    float inaccuracy = 2.0f;
    bool automatic = false;
    //std::shared_ptr<AnimationManager> animationmanger;
    bool started = false;
    std::shared_ptr<Sound> sound_empty;
    //Vec3 viewoffset;
    bool running = false;
    bool holstered = true;
    shared_ptr<Sprite> muzzlesprite;
    float muzzlespriteradius = 0.05f;
    shared_ptr<Sound> sound_reload, sound_shoot;
    uint64_t lastfiretime = 0;
    uint64_t reloadtime = 0;
    int reloadspeed = 2000;
    //std::array<std::shared_ptr<ParticleEmitter>, 3> emitters;
    //int emittercycle = 0;
    int clipsize = 30;
    int loadedammo = clipsize;
    int ammo = 2000;

public:
    //int index = 0;
    int current_animaton;

    FPSGun();

    virtual void DetachFromPlayer(std::shared_ptr<Component> playercomponent);
    virtual bool GetFiring();
    virtual void UpdateMuzzleLight();
    virtual bool CanFire();
    virtual bool CanReload();
    virtual void Start();
    virtual void Update();
    virtual std::shared_ptr<Component> Copy();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra);
    virtual bool ProcessEvent(const Event& e);
    virtual bool PlayerCanRun();
    virtual void Fire();
    virtual void Reload();
    virtual void UpdateBullets();
    virtual bool GetReloading();

    static void AnimationDone(const Leadwerks::WString name, shared_ptr<Leadwerks::Object> object);
    static void ReloadHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
    static void HideHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);

    //virtual void Holster();
    //virtual void UnHolster();
};