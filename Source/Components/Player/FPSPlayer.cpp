#include "Leadwerks.h"
#include "FPSPlayer.h"

using namespace Leadwerks;

FPSPlayer::FPSPlayer()
{
	name = "FPSPlayer";
}

void FPSPlayer::Start()
{
	auto entity = GetEntity();

	// Set the physics mode to PHYSICS_PLAYER, this will enable the character controller.
	entity->SetPhysicsMode(PHYSICS_PLAYER);

	// If the mass happens to be 0, force set the mass to a default value.
	if (entity->GetMass() == 0.0f) entity->SetMass(78);

	// Set the collision type to  COLLISION_PLAYER
	entity->SetCollisionType(COLLISION_PLAYER);

	// Disable shadows
	entity->SetShadows(false);

	// Never render this entity!
	entity->SetRenderLayers(0);

	entity->SetNavObstacle(false);

	entity->RecordCollisions(true);

	if (navmesh)
	{
	//	agent = CreateNavAgent(navmesh, 2, 1.8);
	//	agent->SetPosition(entity->GetPosition(true));
	}
	
	flashlightrotation = camera->GetQuaternion(true);

	// Listen for window events we want to use
	Listen(EVENT_KEYDOWN, NULL);
	Listen(EVENT_KEYUP, NULL);

	for (int n = 0; n < sound_hit.size(); ++n)
	{
		sound_hit[n] = LoadSound("Sound/Impact/bodypunch" + String(n + 1) + ".wav");
	}
	sound_jump = LoadSound("Sound/Footsteps/Concrete/jump.wav");
	sound_flashlight = LoadSound("Sound/Items/flashlightswitch.wav");
	for (int n = 0; n < sound_step.size(); ++n)
	{
		sound_step[n] = LoadSound("Sound/Footsteps/Concrete/step" + String(n + 1)  + ".wav");
	}

	const float scale = 0.25f;
	std::vector<Vec3> points;

	// Add corners for a cube
	points.push_back(Vec3(0.5, 0.5f, 0.5) * scale);
	points.push_back(Vec3(-0.5, 0.5f, 0.5) * scale);
	points.push_back(Vec3(0.5, -0.5f, 0.5) * scale);
	points.push_back(Vec3(-0.5, -0.5f, 0.5) * scale);
	points.push_back(Vec3(0.5, 0.5f, -0.5) * scale);
	points.push_back(Vec3(-0.5, 0.5f, -0.5) * scale);
	points.push_back(Vec3(0.5, -0.5f, -0.5) * scale);
	points.push_back(Vec3(-0.5, -0.5f, -0.5) * scale);

	// Add some points sticking out so the shape rolls a little bit
	points.push_back(Vec3(0.0f, 0.0f, -0.667f) * scale);
	points.push_back(Vec3(0.0f, 0.0f, 0.667f) * scale);
	points.push_back(Vec3(0.0f, -0.667f, 0.0f) * scale);
	points.push_back(Vec3(0.0f, 0.667f, 0.0f) * scale);
	points.push_back(Vec3(-0.667f, 0.0f, 0.0f)* scale);
	points.push_back(Vec3(0.667f, 0.0f, 0.0f) * scale);

	deadbodycollider = CreateConvexHullCollider(points);

	Player::Start();
}

void FPSPlayer::Kill(shared_ptr<Entity> attacker)
{
	auto entity = GetEntity();
	camera->SetParent(NULL);
	camera->SetCollider(deadbodycollider);
	camera->SetVelocity(entity->GetVelocity());
	camera->SetMass(10);
	camera->SetCollisionType(COLLISION_PROP);
	camera->AddTorque(50, Random(-20, 20), Random(-20, 20));
	if (weapon) weapon->DetachFromPlayer(As<Player>());
	weapon = NULL;
	entity->SetMass(0);
	entity->SetCollisionType(COLLISION_NONE);
	entity->SetCollider(NULL);
	entity->SetPhysicsMode(PHYSICS_DISABLED);
	if (flashlight) flashlight->SetHidden(true);
}

void FPSPlayer::ToggleFlashlight()
{
	if (flashlight == NULL or flashlight->GetHidden())
	{
		ShowFlashlight();
	}
	else
	{
		HideFlashlight();
	}
}

void FPSPlayer::ShowFlashlight()
{
	if (sound_flashlight) sound_flashlight->Play();
	if (flashlight == NULL or flashlight->GetHidden())
	{
		if (not flashlight)
		{
			auto entity = GetEntity();
			auto world = entity->GetWorld();
			flashlight = CreateSpotLight(world);
			flashlight->SetConeAngles(20, 10);
			flashlight->SetRange(0.01, 10);
		}
		flashlightrotation = camera->GetQuaternion(true);
		flashlight->SetHidden(false);
		UpdateFlashlight();
		FireOutputs("ShowFlashlight");
	}
}

void FPSPlayer::HideFlashlight()
{
	if (flashlight)
	{
		flashlight->SetHidden(true);
		FireOutputs("HideFlashlight");
	}
}

bool FPSPlayer::ProcessEvent(const Event& e)
{
	if (not GetEnabled()) return true;
	if (GetHealth() <= 0) return true;

	auto entity = GetEntity();
	auto world = entity->GetWorld();
	switch (e.id)
	{
	case EVENT_KEYDOWN:
		if (e.data == KEY_SPACE)
		{
			jumpkey = true;
		}
		else if (e.data == KEY_SHIFT)
		{
			//if (weapon and not weapon->PlayerCanRun()) return true;
			//running = true;
		}
		else if (e.data == KEY_F)
		{
			ToggleFlashlight();
		}
		else if (e.data == KEY_E)
		{
			if (world)
			{
				auto pos = entity->GetPosition(true);
				Aabb bounds = Aabb(pos - 2.0f, pos + 2.0f);
				auto entities = world->GetEntitiesInArea(bounds.min, bounds.max);
				for (auto e : entities)
				{
					if (e == entity) continue;
					for (auto c : e->components)
					{
						auto base = c->As<BaseComponent>();
						if (base and base->GetEnabled()) base->Use(entity);
					}
				}
			}
		}
		break;
	case EVENT_KEYUP:
		if (e.data == KEY_SPACE)
		{
			jumpkey = false;
		}
		else if (e.data == KEY_SHIFT)
		{
			//running = false;
		}
		break;
	}
	return true;
}

static bool UnCrouchFilter(std::shared_ptr<Entity> entity, std::shared_ptr<Object> extra)
{
	if (entity == extra->As<Entity>())
		return false;

	if (entity->GetCollider() == NULL || entity->GetCollisionType() == COLLISION_NONE
		|| entity->GetCollisionType() == COLLISION_TRIGGER) {
		return false;
	}

	return true;
}

void FPSPlayer::Update()
{
	if (not GetEnabled()) return;
	if (GetHealth() <= 0) return;

	//Disable running if it is not allowed
	if (running and weapon and weapon->PlayerCanRun() == false) running = false;
	movement = 0.0f;

	float jump = 0;
	bool crouchkey = false;
	static bool crouched = false;

	auto entity = GetEntity();

	auto world = entity->GetWorld();
	
	auto window = ActiveWindow();
	if (window)
	{
		running = window->KeyDown(KEY_SHIFT);

		auto cx = Round((float)window->GetFramebuffer()->GetSize().x / 2);
		auto cy = Round((float)window->GetFramebuffer()->GetSize().y / 2);
		auto mpos = window->GetMousePosition();
		if (doResetMousePosition) {
			window->SetMousePosition(cx, cy);
		}
		auto centerpos = window->GetMousePosition();

		if (freelookstarted)
		{
			float looksmoothing = mousesmoothing; //0.5f;
			float lookspeed = mouselookspeed / 10.0f;

			float dx = mpos.x - centerpos.x;
			float dy = mpos.y - centerpos.y;

			if (looksmoothing > 0.0f)
			{
				mousedelta.x = CurveValue(dx, mousedelta.x, 1.0f + looksmoothing);
				mousedelta.y = CurveValue(dy, mousedelta.y, 1.0f + looksmoothing);
			}
			else
			{
				mousedelta.x = dx;
				mousedelta.y = dy;
			}

			freelookrotation.x = Clamp(freelookrotation.x + mousedelta.y * lookspeed, -90.0f, 90.0f);
			freelookrotation.y += mousedelta.x * lookspeed;
			camera->SetRotation(freelookrotation, true);
			freelookmousepos = Vec3(mpos.x, mpos.y);
		}
		else
		{
			freelookstarted = true;
			freelookrotation = camera->GetRotation(true);
			freelookmousepos = Vec3(window->GetMousePosition().x, window->GetMousePosition().y);
			window->SetCursor(CURSOR_NONE);
		}

		if (window->KeyHit(KEY_G))
		{
			float a = Random(360.0f);
			camerashakerotation = Quat(Vec3(Cos(a) * 30.0f, Sin(a) * 30.0f, 0.0f));
		}
		// Camera shake when hit
		float speed = 0.1f;
		float diff = Vec4(camerashakerotation.x, camerashakerotation.y, camerashakerotation.z, camerashakerotation.w).Length();
		camerashakerotation = camerashakerotation.Slerp(Quat(0,0,0,1), Min(1.0f, speed / diff));
		smoothedcamerashakerotation = smoothedcamerashakerotation.Slerp(camerashakerotation, 0.5f);
		camera->Turn(smoothedcamerashakerotation.ToEuler(), false);

		// We use the base class' enabled bool to lock the movement.
		if (GetEnabled())
		{
			float speed = movespeed;
			crouchkey = window->KeyDown(KEY_C);
			if (entity->GetAirborne())
			{
				speed *= 0.25f;
			}
			else
			{
				if (running)
				{
					speed *= 2.0f;
				}
				else if (crouched)
				{
					speed *= 0.5f;
				}

				if (jumpkey && !crouched)
				{
					jump = jumpforce;
					if (sound_jump) sound_jump->Play();
				}
			}
			if (window->KeyDown(KEY_D)) movement.x += speed;
			if (window->KeyDown(KEY_A)) movement.x -= speed;
			if (window->KeyDown(KEY_W)) movement.z += speed;
			if (window->KeyDown(KEY_S)) movement.z -= speed;
			if (movement.x != 0.0f and movement.z != 0.0f) movement *= 0.707f;
			if (jump != 0.0f)
			{
				movement.x *= jumplunge;
				if (movement.z > 0.0f) movement.z *= jumplunge;
			}
		}
	}

	entity->SetInput(camera->rotation.y, movement.z, movement.x, jump, crouchkey);

	if (agent) agent->SetPosition(entity->GetPosition(true));

	static float eye = eyeheight;
	if (entity->GetCrouched())
	{
		if (not entity->GetAirborne()) eye = croucheyeheight;
		crouched = true;
	}
	else
	{
		eye = eyeheight;
		crouched = false;
	}

	float y = TransformPoint(currentcameraposition, nullptr, entity).y;
	float h = eye;
	if (not entity->GetAirborne() and (y < eye || eye != eyeheight)) h = Mix(y, eye, 0.25f);
	currentcameraposition = TransformPoint(0, h, 0, entity, nullptr);
	camera->SetPosition(currentcameraposition, true);

	if (maxlean > 0.0f)
	{
		auto localpos = TransformPoint(camera->GetPosition(true), NULL, entity);
		if (window->KeyDown(KEY_E)) lean -= leanspeed;
		if (window->KeyDown(KEY_Q)) lean += leanspeed;
		lean = Clamp(lean, -maxlean, maxlean);
		if (lean != 0.0f)
		{
			camera->SetPosition(entity->GetPosition(true), true);
			auto r = camera->GetRotation(true);
			camera->SetRotation(0, r.y, 0, true);
			camera->Turn(0, 0, lean);
			camera->Move(localpos);
			camera->Turn(r.x, 0, 0);
		}
		if (window->KeyDown(KEY_E) == false and window->KeyDown(KEY_Q) == false)
		{
			if (lean > 0.0f)
			{
				lean -= leanspeed;
				lean = Max(lean, 0.0f);
			}
			else if (lean < 0.0f)
			{
				lean += leanspeed;
				lean = Min(lean, 0.0f);
			}
		}
	}

	UpdateFlashlight();
	UpdateFootsteps();

	jumpkey = false;
}

std::any FPSPlayer::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
	if (name == "ShowFlashlight")
	{
		ShowFlashlight();
	}
	else if (name == "HideFlashlight")
	{
		HideFlashlight();
	}
	return BaseComponent::CallMethod(caller, name, args);
}

void FPSPlayer::UpdateFootsteps()
{
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (not world) return;
	if (not entity->GetAirborne() and movement.Length() > 0.0f)
	{
		auto now = world->GetTime();
		float speed = entity->GetVelocity().xz().Length();
		int footsteptime = Clamp(500.0f * this->movespeed / speed, 250.0f, 1000.0f);
		if (now - lastfootsteptime > footsteptime)
		{
			lastfootsteptime = now;
			int index = Round(Random(0, sound_step.size() - 1));
			if (sound_step[index]) sound_step[index]->Play();
		}
	}
}

void FPSPlayer::UpdateFlashlight()
{
	if (flashlight)
	{
		auto pos = camera->GetPosition(true);
		pos += TransformNormal(0, -1, 0, camera, NULL) * 0.25f;
		pos += TransformNormal(1, 0, 0, camera, NULL) * 0.25f;
		flashlight->SetPosition(pos, true);
		flashlightrotation = flashlightrotation.Slerp(camera->GetQuaternion(true), 0.2f);
		flashlight->SetRotation(flashlightrotation, true);
	}
}

void FPSPlayer::Damage(const int amount, shared_ptr<Entity> attacker)
{
	Player::Damage(amount, attacker);
	if (GetHealth() <= 0) return;
	{
		float a = Random(360.0f);
		camerashakerotation = Quat(Vec3(Cos(a) * 45.0f, Sin(a) * 45.0f, 0.0f));
	}
	int index = Round(Random(0, sound_hit.size() - 1));
	if (sound_hit[index])
	{
		sound_hit[index]->Play();
	}
}

void FPSPlayer::Collide(shared_ptr<Entity> collidedentity, const Vec3& position, const Vec3& normal, const float speed)
{
}

//This method will work with simple components
shared_ptr<Component> FPSPlayer::Copy()
{
	auto copy = std::make_shared<FPSPlayer>(*this);
	auto entity = GetEntity();
	if (entity)
	{
		auto world = entity->GetWorld();
		if (world) copy->camera = CreateCamera(world);
		copy->GetEntity()->extra = copy->camera;
	}
	return copy;
}

bool FPSPlayer::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra)
{
	auto entity = GetEntity();
	auto world = entity->GetWorld();

	if (camera == NULL and world != NULL)
	{
		camera = CreateCamera(world);
		//camera->SetDebugPhysicsMode(true);
		camera->name = entity->name + "Camera";
		camera->Listen();

		auto pos = entity->GetPosition(true);
		camera->SetPosition(pos.x, pos.y + eyeheight, pos.z);
		camera->SetRotation(0, 0, 0);
		camera->SetFov(fov);

		// Push the camera to the scene.
		// This makes it so we don't have to worry about saving the camera's rotation.
		//scene->entities.push_back(camera);

		// Store the position into 
		currentcameraposition = camera->GetPosition(true);

		// Last, store the camera into this entity's extra member.
		// It's gonna be a lot easier to grab from other components this way.
		GetEntity()->extra = camera;

		// If there's no camera, we have a problem!
		Assert(camera, "FPSPlayer: Failed to create camera!");
	}
	
	navmesh = NULL;
	if (not scene->navmeshes.empty()) navmesh = scene->navmeshes[0];

	// Reset the look everytime we reload.
	freelookstarted = false;
	if (camera) freelookrotation = camera->GetRotation(true);

	// Load values.
	if (properties["fov"].is_number()) fov = properties["fov"];
	if (properties["eyeheight"].is_number()) eyeheight = properties["eyeheight"];
	if (properties["croucheyeheight"].is_number()) croucheyeheight = properties["croucheyeheight"];
	if (properties["mouselookspeed"].is_number()) mouselookspeed = properties["mouselookspeed"];
    if (properties["mousesmoothing"].is_number()) mousesmoothing = properties["mousesmoothing"];
    if (properties["mouselookspeed"].is_number()) mouselookspeed = properties["mouselookspeed"];
    if (properties["movespeed"].is_number()) movespeed = properties["movespeed"];
	if (properties["jumpforce"].is_number()) jumpforce = properties["jumpforce"];
	if (properties["jumplunge"].is_number()) jumplunge = properties["jumplunge"];
	weapons.clear();
	weapons.resize(4);
	for (int n = 0; n < weapons.size(); ++n)
	{
		if (properties["slot" + String(n)].is_string())
		{
			WString path = std::string(properties["slot" + String(n)]);
			weapons[n] = LoadPrefab(world, path);
		}
	}

	if (properties["intialslot"].is_number())
	{
		initialslot = properties["integervalue"];
		if (initialslot >= 0 and initialslot < weapons.size())
		{
			if (weapons[initialslot])
			{
				auto player = entity->GetComponent<FPSPlayer>();
				if (player)
				{
					auto weapon = weapons[initialslot]->GetComponent<FPSWeapon>();
					if (weapon) weapon->AttachToPlayer(player);
				}
			}
		}
	}
	selectedslot = initialslot;

	// The member "enabled" is located in the base component class.
	return Player::Load(properties, binstream, scene, flags, extra);;
}

bool FPSPlayer::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra)
{
	// Store the values into the table.
	properties["fov"] = fov;
	properties["eyeheight"] = eyeheight;
	properties["croucheyeheight"] = croucheyeheight;
	properties["mousesmoothing"] = mousesmoothing;
	properties["mouselookspeed"] = mouselookspeed;
	properties["movespeed"] = movespeed;
	properties["jumpforce"] = jumpforce;
	properties["jumplunge"] = jumplunge;

	// The member "enabled" is located in the base component class.
	return Player::Save(properties, binstream, scene, flags, extra);
}
