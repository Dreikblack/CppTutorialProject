#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"
#include "../Weapons/FPSWeapon.h"
#include "Player.h"

using namespace Leadwerks;

class FPSWeapon;
class PlayerInteraction;

class FPSPlayer : public Player
{
protected:
	shared_ptr<Collider> deadbodycollider;
	std::shared_ptr<Sound> sound_jump;
	std::array<std::shared_ptr<Sound>, 4> sound_step;
	std::array<std::shared_ptr<Sound>, 3> sound_hit;
    bool freelookstarted{ false };
	Vec3 freelookmousepos;
	Vec3 freelookrotation;
	Vec2 lookchange;
	Vec2 mousedelta;
	Vec3 currentcameraposition;
	uint64_t lastfootsteptime = 0;
	bool jumpkey = false;
	bool running = false;
	float lean = 0.0f;
	float maxlean = 0.0f;// up to 10 is good
	float leanspeed = 1.0f;
	std::shared_ptr<NavMesh> navmesh;
	std::shared_ptr<NavAgent> agent;
	Quat camerashakerotation;
	Quat smoothedcamerashakerotation;
	std::shared_ptr<SpotLight> flashlight;
	std::shared_ptr<Sound> sound_flashlight;
	Quat flashlightrotation;
	std::vector<shared_ptr<Entity> > weapons;
	int selectedslot, initialslot;
	Vec3 movement;

public:
	shared_ptr<Camera> camera;
	shared_ptr<FPSWeapon> weapon;

	float fov = 54.0f;
	float eyeheight = 1.65f;
	float croucheyeheight = 0.7f;
	float mousesmoothing = 0.0f;
	float mouselookspeed = 1.0f;
	float movespeed = 4.0f;
	float jumpforce = 4.2f;
	float jumplunge = 1.2f;
	bool doResetMousePosition = true;
	FPSPlayer();

	virtual void Start();
	virtual void Update();
	virtual void UpdateFlashlight();
	virtual void ShowFlashlight();
	virtual void HideFlashlight();
	virtual void ToggleFlashlight();
	virtual void Kill(shared_ptr<Entity> attacker);
	virtual bool ProcessEvent(const Event& e);
	virtual void Collide(shared_ptr<Entity> collidedentity, const Vec3& position, const Vec3& normal, const float speed);
	virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra);
	virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra);
	virtual void Damage(const int amount, shared_ptr<Entity> attacker);
	virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
	virtual void UpdateFootsteps();
	virtual shared_ptr<Component> Copy();

	friend class PlayerInteraction;
};