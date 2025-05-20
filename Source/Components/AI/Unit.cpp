#pragma once
#include "Leadwerks.h"
#include "Unit.h"
#include "../Logic/WayPoint.h"

using namespace Leadwerks;

Unit::Unit() {
	name = "Unit";
	attackName = "Attack";
	idleName = "Idle";
	painName = "Pain";
	deathName = "Death";
	runName = "Run";
}

shared_ptr<Component> Unit::Copy() {
	return std::make_shared<Unit>(*this);
}

void Unit::Start() {
	auto entity = GetEntity();
	auto model = entity->As<Model>();
	entity->AddTag("Unit");
	//for custom save/load system
	entity->AddTag("Save");
	if (!isFullPlayerControl) {
		//checking efficiently if Unit have a nav mesh
		if (!navMesh.expired()) {
			//1 m radius because of Beast long model, 0.5 would better otherwise, 2 m height
			agent = CreateNavAgent(navMesh.lock(), 0.5, 2);
			agent->SetMaxSpeed(speed);
			agent->SetPosition(entity->GetPosition(true));
			agent->SetRotation(entity->GetRotation(true).y);
			entity->SetPosition(0, 0, 0);
			//becase models rotated by back
			entity->SetRotation(0, 180, 0);
			entity->Attach(agent);
		}
		entity->SetCollisionType(COLLISION_PLAYER);
		entity->SetMass(0);
		entity->SetPhysicsMode(PHYSICS_RIGIDBODY);
	}
	if (model) {
		auto seq = model->FindAnimation(attackName);
		if (seq != -1) {
			int count = model->CountAnimationFrames(seq);
			//to disable attack state at end of attack animation
			model->skeleton->AddHook(seq, count - 1, EndAttackHook, Self());
			//to deal damage to target at range at specific animation frame
			model->skeleton->AddHook(seq, attackFrame, AttackHook, Self());
		}
		seq = model->FindAnimation(painName);
		if (seq != -1) {
			int count = model->CountAnimationFrames(seq);
			//to disable pain state at end of pain animation
			model->skeleton->AddHook(seq, count - 1, EndPainHook, Self());
		}
		if (health <= 0) {
			seq = model->FindAnimation(deathName);
			int count = model->CountAnimationFrames(seq);
			model->Animate(deathName, 1.0f, 250, ANIMATION_ONCE, count - 1);
		}
	}
	if (!isFullPlayerControl) {
		int healthBarHeight = 5;
		healthBar = CreateTile(cameraWeak.lock(), maxHealth, healthBarHeight);
		if (team == 1) {
			healthBar->SetColor(0, 1, 0);
		} else {
			healthBar->SetColor(1, 0, 0);
		}
		healthBar->SetPosition(0, 0, 0.00001f);
		healthBar->SetScale((float)health / (float)maxHealth, 1);
		healthBarBackground = CreateTile(cameraWeak.lock(), maxHealth, healthBarHeight);
		healthBarBackground->SetColor(0.1f, 0.1f, 0.1f);
		//to put it behind health bar
		healthBarBackground->SetPosition(0, 0, 0.00002f);
	}
	auto world = entity->GetWorld();
	shared_ptr<Camera> camera;
	for (auto const& cameraEntity : world->GetTaggedEntities("Camera")) {
		camera = cameraEntity->As<Camera>();
		break;
	}
	if (!camera) {
		for (auto const& cameraEntity : world->GetEntities()) {
			camera = cameraEntity->As<Camera>();
			if (camera) {
				break;
			}
		}
	}
	cameraWeak = camera;
	if (!isFullPlayerControl) {
		int healthBarHeight = 5;
		healthBar = CreateTile(camera, maxHealth, healthBarHeight);
		if (team == 1) {
			healthBar->SetColor(0, 1, 0);
		} else {
			healthBar->SetColor(1, 0, 0);
		}
		//to put it before health bar
		healthBar->SetOrder(1);
		healthBarBackground = CreateTile(camera, maxHealth, healthBarHeight);
		healthBarBackground->SetColor(0.1f, 0.1f, 0.1f);
		healthBarBackground->SetOrder(0);
	}
	BaseComponent::Start();
}

bool Unit::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	sceneWeak = scene;
	if (properties["isFullPlayerControl"].is_boolean()) isFullPlayerControl = properties["isFullPlayerControl"];
	if (properties["isPlayer"].is_boolean()) isPlayer = properties["isPlayer"];
	if (properties["isSelected"].is_boolean()) isSelected = properties["isSelected"];
	if (properties["team"].is_number()) team = properties["team"];
	if (properties["health"].is_number()) health = properties["health"];
	if (properties["maxHealth"].is_number()) maxHealth = properties["maxHealth"];
	if (properties["attackDamage"].is_number()) attackDamage = properties["attackDamage"];
	if (properties["attackRange"].is_number()) attackRange = properties["attackRange"];
	if (properties["attackFrame"].is_number()) attackFrame = properties["attackFrame"];
	if (properties["painCooldown"].is_number()) painCooldown = properties["painCooldown"];
	if (properties["enabled"].is_boolean()) enabled = properties["enabled"];
	if (properties["decayTime"].is_number()) decayTime = properties["decayTime"];
	if (properties["attackName"].is_string()) attackName = properties["attackName"];
	if (properties["idleName"].is_string()) idleName = properties["idleName"];
	if (properties["deathName"].is_string()) deathName = properties["deathName"];
	if (properties["painName"].is_string()) painName = properties["painName"];
	if (properties["runName"].is_string()) runName = properties["runName"];
	if (properties["painSound"].is_string()) painSound = LoadSound(std::string(properties["painSound"]));
	if (properties["target"].is_string()) {
		std::string id = properties["target"];
		targetWeak = scene->GetEntity(id);
	} else {
		targetWeak.reset();
	}
	if (properties["targetPoint"].is_string()) {
		std::string id = properties["targetPoint"];
		targetPoint = scene->GetEntity(id);
	} else {
		targetPoint = nullptr;
	}
	if (properties["isForcedMovement"].is_boolean()) isForcedMovement = properties["isForcedMovement"];
    navMesh.reset();
	if (!scene->navmeshes.empty()) {
        navMesh = scene->navmeshes[0];
	}
	return BaseComponent::Load(properties, binstream, scene, flags, extra);
}

bool Unit::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	properties["isFullPlayerControl"] = isFullPlayerControl;
	properties["isPlayer"] = isPlayer;
	properties["isSelected"] = isSelected;
	properties["team"] = team;
	properties["health"] = health;
	properties["enabled"] = enabled;
	if (targetWeak.lock()) {
		properties["target"] = targetWeak.lock()->GetUuid();
	}
	if (targetPoint) {
		properties["targetPoint"] = targetPoint->GetUuid();
	}
	properties["isForcedMovement"] = isForcedMovement;
	return BaseComponent::Save(properties, binstream, scene, flags, extra);
}

void Unit::Damage(const int amount, shared_ptr<Entity> attacker) {
	if (!isAlive()) {
		return;
	}
	health -= amount;
	auto world = GetEntity()->GetWorld();
	if (!world) {
		return;
	}
	auto bloodHit = LoadPrefab(world, "Prefabs/BloodHit.pfb");
	auto entity = GetEntity();
	if (bloodHit) {
		auto bloodHitPosition = entity->GetPosition(true);
		//to lift it up to entity center
		bloodHitPosition.y = bloodHitPosition.y + entity->GetBounds(BOUNDS_GLOBAL).size.height / 2;
		bloodHit->SetPosition(bloodHitPosition, true);
		//prefabs component are not started after its load so will do it manually
		for (auto const& component : bloodHit->components) {
			component->Start();
		}
	}
	if (painSound) {
		entity->EmitSound(painSound);
	}
	auto now = world->GetTime();
	if (health <= 0) {
		Kill(attacker);
	} else if (!isInPain && now - painCooldownTime > painCooldown) {
		isInPain = true;
		isAttacking = false;
		auto model = GetEntity()->As<Model>();
		if (model) {
			model->StopAnimation();
			model->Animate(painName, 1.0f, 100, ANIMATION_ONCE);
		}
		if (agent) {
			agent->Stop();
		}
	}
	if (healthBar) {
		//reducing health bar tile width
		healthBar->SetScale((float)health / (float)maxHealth, 1);
	}
	//attack an atacker
	if (!isForcedMovement && !isForcedTarget) {
		attack(attacker);
	}
}

void Unit::Kill(shared_ptr<Entity> attacker) {
	auto entity = GetEntity();
	if (!entity) {
		return;
	}
	auto scene = sceneWeak.lock();
	auto bloodPuddle = LoadPrefab(entity->GetWorld(), "Prefabs/BloodPuddle.pfb");
	if (bloodPuddle && scene) {
		auto bloodHitPosition = entity->GetPosition(true);
		bloodPuddle->SetPosition(bloodHitPosition, true);
		//to keep it
		scene->AddEntity(bloodPuddle);
	}
	auto model = entity->As<Model>();
	if (model) {
		model->StopAnimation();
		model->Animate(deathName, 1.0f, 250, ANIMATION_ONCE);
	}
	if (agent) {
		//This method will cancel movement to a destination, if it is active, and the agent will smoothly come to a halt.
		agent->Stop();
	}
	//to remove nav agent
	entity->Detach();
	agent = nullptr;
	//to prevent it being obstacle
	entity->SetCollisionType(COLLISION_NONE);
	//to prevent selection
	entity->SetPickMode(PICK_NONE);
	isAttacking = false;
	healthBar = nullptr;
	healthBarBackground = nullptr;
	if (decayTime > 0) {
		removeEntityTimer = UltraEngine::CreateTimer(decayTime);
		ListenEvent(EVENT_TIMERTICK, removeEntityTimer, RemoveEntityCallback, Self());
		//not saving if supposed to be deleted anyway
		entity->RemoveTag("Save");
	}
}

bool Unit::isAlive() {
	return health > 0 && GetEntity();
}

bool Unit::RemoveEntityCallback(const UltraEngine::Event& ev, shared_ptr<UltraEngine::Object> extra) {
	auto unit = extra->As<Unit>();
	unit->removeEntityTimer->Stop();
	unit->removeEntityTimer = nullptr;
	unit->sceneWeak.lock()->RemoveEntity(unit->GetEntity());
	return false;
}

void Unit::scanForTarget() {
	auto entity = GetEntity();
	auto world = entity->GetWorld();
	if (world) {
		//We only want to perform this few times each second, staggering the operation between different entities.
		//Pick() operation is kinda CPU heavy. It can be noticeable in Debug mode when too much Picks() happes in same game cycle.
		//Did not notice yet it in Release mode, but it's better to have it optimized Debug as well anyway.
		auto now = world->GetTime();
		if (now < nextScanForTargetTime) {
			return;
		}
		nextScanForTargetTime = now + Random(100, 200);

		auto entityPosition = entity->GetPosition(true);
		Vec3 positionLower = entityPosition;
		positionLower.x = positionLower.x - perceptionRadius;
		positionLower.z = positionLower.z - perceptionRadius;
		positionLower.y = positionLower.y - perceptionRadius;

		Vec3 positionUpper = entityPosition;
		positionUpper.x = positionUpper.x + perceptionRadius;
		positionUpper.z = positionUpper.z + perceptionRadius;
		positionUpper.y = positionUpper.y + perceptionRadius;
		//will use it to determinate which target is closest
		float currentTargetDistance = -1;
		//GetEntitiesInArea takes positions of an opposite corners of a cube as params
		for (auto const& foundEntity : world->GetEntitiesInArea(positionLower, positionUpper)) {
			auto foundUnit = foundEntity->GetComponent<Unit>();
			//targets are only alive enemy units
			if (!foundUnit || !foundUnit->isAlive() || !foundUnit->isEnemy(team) || !foundUnit->GetEntity()) {
				continue;
			}
			float dist = foundEntity->GetDistance(entity);
			if (dist > perceptionRadius) {
				continue;
			}
			//check if no obstacles like walls between units
			auto pick = world->Pick(entity->GetBounds(BOUNDS_RECURSIVE).center, foundEntity->GetBounds(BOUNDS_RECURSIVE).center, perceptionRadius, true, RayFilter, Self());
			if (dist < 0 || currentTargetDistance < dist) {
				targetWeak = foundEntity;
				currentTargetDistance = dist;
			}
		}
	}
}

void Unit::Update() {
    if (!GetEnabled() || !isAlive()) {
        return;
    }
    auto entity = GetEntity();
	auto world = entity->GetWorld();
	auto model = entity->As<Model>();
	if (!world || !model) {
		return;
	}
	if (isFullPlayerControl) {
		return;
	}
	//making health bar fllow the unit
	auto window = ActiveWindow();
	if (window && healthBar && healthBarBackground) {
		auto framebuffer = window->GetFramebuffer();
		auto position = entity->GetBounds().center;
		position.y += entity->GetBounds().size.height / 2;//take top position of unit
		shared_ptr<Camera> camera = cameraWeak.lock();	
		if (camera) {
			//transorming 3D position into 2D
			auto unitUiPosition = camera->Project(position, framebuffer);
			unitUiPosition.x -= healthBarBackground->size.x / 2;
			healthBar->SetPosition(unitUiPosition.x, unitUiPosition.y);
			healthBarBackground->SetPosition(unitUiPosition.x, unitUiPosition.y);
			bool doShow = isSelected || (health != maxHealth && !isPlayer);
			healthBar->SetHidden(!doShow);
			healthBarBackground->SetHidden(!doShow);
		}
	}
	//can't attack or move while pain animation
	if (isInPain) {
		return;
	}
	bool isMoving = false;
	//ignore enemies and move
	if (isForcedMovement && goTo()) {
		return;
	}
	//atacking part
	if (!isMoving) {
		auto target = targetWeak.lock();
		// Stop attacking if target is dead
		if (target) {
			float distanceToTarget = entity->GetDistance(target);
			bool doResetTarget = false;
			if (distanceToTarget > chaseMaxDistance && !isForcedTarget) {
				doResetTarget = true;
			} else {
				for (auto const& targetComponent : target->components) {
					auto targetUnit = targetComponent->As<Unit>();
					if (targetUnit && !targetUnit->isAlive()) {
						doResetTarget = true;
						isForcedTarget = false;					
					}
					break;
				}
			}
			if (doResetTarget) {
				target.reset();
				targetWeak.reset();
				if (agent) {
					agent->Stop();
				}
			}
			
		}
		if (isAttacking && target != nullptr) {
			//rotating unit to target
			float a = ATan(entity->matrix.t.x - target->matrix.t.x, entity->matrix.t.z - target->matrix.t.z);
			if (agent) {
				agent->SetRotation(a + 180);
			}
		}
		if (!target) {
			scanForTarget();
		}
		if (target) {
			float distanceToTarget = entity->GetDistance(target);
			//run to target if out of range
			if (distanceToTarget > attackRange) {
				if (agent) {
					agent->Navigate(target->GetPosition(true));
				}
				model->Animate(runName, 1.0f, 250, ANIMATION_LOOP);
			} else {
				if (agent) {
					agent->Stop();
				}
				//start attack if did not yet
				if (!isAttacking) {
					meleeAttackTime = world->GetTime();
					model->Animate(attackName, 1.0f, 100, ANIMATION_ONCE);
					isAttacking = true;
				}
			}
			return;
		}
	}
	if (targetPoint && goTo()) {
		return;
	}
	if (!isAttacking) {
		model->Animate(idleName, 1.0f, 250, ANIMATION_LOOP);
		if (agent) {
			agent->Stop();
		}
	}
}

bool Unit::RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra) {
	shared_ptr<Unit> thisUnit = extra->As<Unit>();
	shared_ptr<Unit> pickedUnit = entity->GetComponent<Unit>();
	//skip if it's same team
	return pickedUnit == nullptr || pickedUnit && pickedUnit->team != thisUnit->team;
}

void Unit::AttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra) {
	auto unit = std::dynamic_pointer_cast<Unit>(extra);
	if (!unit) {
		return;
	}
	auto entity = unit->GetEntity();
	auto target = unit->targetWeak.lock();
	if (target) {
		auto pos = entity->GetPosition(true);
		auto dest = target->GetPosition(true) + target->GetVelocity(true);
		//attack in target in range
		if (pos.DistanceToPoint(dest) < unit->attackRange) {
			for (auto const& targetComponent : target->components) {
				auto base = targetComponent->As<BaseComponent>();
				if (base) {
					base->Damage(unit->attackDamage, entity);
				}
			}
		}
	}	
}

void Unit::EndAttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra) {
	auto unit = std::dynamic_pointer_cast<Unit>(extra);
	if (unit) {
		unit->isAttacking = false;
	}
}

void Unit::EndPainHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra) {
	auto unit = extra->As<Unit>();
	if (unit) {
		unit->isInPain = false;
		if (unit->isAlive() && unit->GetEntity()->GetWorld()) {
			unit->painCooldownTime = unit->GetEntity()->GetWorld()->GetTime();
		}
	}
}

bool Unit::isEnemy(int otherUnitTeam) const {
	return team == 1 && otherUnitTeam == 2 || team == 2 && otherUnitTeam == 1;
}

void Unit::goTo(Vec3 positionToGo, bool isForced) {
	auto entity = GetEntity();
	if (entity) {
		isForcedMovement = isForced;
		auto prefabPivot = LoadPrefab(entity->GetWorld(), "Prefabs/WayPoint.pfb");
		targetPoint = prefabPivot ? prefabPivot : CreatePivot(entity->GetWorld());
		targetPoint->SetPosition(positionToGo);
		goTo();
	}
}

void Unit::goTo(shared_ptr<Entity> targetPointEntity, bool isForced) {
	if (targetPointEntity) {
		isForcedMovement = isForced;
		targetPoint = targetPointEntity;
		goTo();
	}
}

bool Unit::goTo() {
	bool doMove = false;
	auto entity = GetEntity();
	auto model = entity->As<Model>();
	if (targetPoint && agent) {
		doMove = agent->Navigate(targetPoint->GetPosition(true), 100, 2.0f);
		if (doMove) {
			//checking distance to target point on nav mesh
			float distanceToTarget = entity->GetDistance(agent->GetDestination());
			float resultMaxDistance = isForcedMovement ? targetPointDistance * 2 : targetPointDistance;
			if (distanceToTarget < resultMaxDistance) {
				auto wayPoint = targetPoint->GetComponent<WayPoint>();
				if (wayPoint && wayPoint->getNextPoint()) {
					targetPoint = wayPoint->getNextPoint();
					doMove = true;
				} else {
					targetPoint.reset();
					doMove = false;
				}
			} else {
				doMove = true;
			}
		}	
		if (doMove && model) {
			model->Animate(runName, 1.0f, 250, ANIMATION_LOOP);
		}
	}
	return doMove;
}


void Unit::attack(shared_ptr<Entity> entityToAttack, bool isForced) {
	targetWeak.reset();
	if (!entityToAttack || !entityToAttack->GetComponent<Unit>() || entityToAttack->GetComponent<Unit>()->team == team) {
		return;
	}
	targetPoint.reset();
	isForcedMovement = false;
	isForcedTarget = isForced;
	targetWeak = entityToAttack;
}

void Unit::select(bool doSelect) {
	isSelected = doSelect;
}
