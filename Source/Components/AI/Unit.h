#pragma once
#include "UltraEngine.h"
#include "../BaseComponent.h"

using namespace UltraEngine;

//abstract class which will be a parent for other units classes such as Beast and Hunter
//partly based of Enemy/Monster/Player default classes
class Unit : public BaseComponent {
protected:
	int health = 100;
	int maxHealth = 100;
	//used for AI navigation, weak_ptr just to make sure that component will not keep it if stays after map unload somehow
	std::weak_ptr<NavMesh> navMesh;
	//unique per entity so shared_ptr
	//NavAgent used to create to plot navigation paths in NavMesh
	std::shared_ptr<NavAgent> agent;
	//how far AI see its enemies in meters
	float perceptionRadius = 10;
	//how long to pursue when out of radius
	float chaseMaxDistance = perceptionRadius * 2;
	//is target a priority
	bool isForcedTarget = false;
	//target to follow and attack if possible
	std::weak_ptr<Entity> targetWeak;
	//to avoid fighting
	bool isForcedMovement = false;
	//which distance to point should be to reach it
	float targetPointDistance = 0.5f;
	//place to reach
	std::shared_ptr<Entity> targetPoint;
	//is attack animation playing
	bool isAttacking = false;
	//when attack started
	uint64_t meleeAttackTime = 0;
	//do damage in meleeAttackTiming after attack start
	int attackFrame = 5;
	float attackRange = 2.0f;
	int attackDamage = 30;
	//pain/git hit state
	bool isInPain = false;
	//can't start new pain animation immediately to avoid infinite stugger
	int painCooldown = 300;
	//when pain animation started
	uint64_t painCooldownTime;
	//how fast unit is
	float speed = 3.0;
	//when to try scan again
	uint64_t nextScanForTargetTime = 0ULL;//unsigned long long
	//animations names
	WString attackName;
	WString idleName;
	WString painName;
	WString deathName;
	WString runName;
	//health bar above unit
	shared_ptr<Sprite> healthBar;
	shared_ptr<Sprite> healthBarBackground;
	bool isSelected = false;
	virtual void scanForTarget();
	bool goTo();
	//pick filter
	static bool RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra);
	//attack target if in range
	static void AttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
	//disable attacking state
	static void EndAttackHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
	//disable pain state
	static void EndPainHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra);
public:
	int team = 0;//0 neutral, 1 player team, 2 enemy
	bool isPlayer = false;
	Unit();
	shared_ptr<Component> Copy() override;
	void Start() override;
	bool Load(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	bool Save(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	//deal a damage to this unit by attacker
	void Damage(const int amount, shared_ptr<Entity> attacker) override;
	//kill this unit by attacker
	void Kill(shared_ptr<Entity> attacker) override;
	bool isAlive();
	void Update() override;
	bool isEnemy(int otherUnitTeam) const;
	void goTo(Vec3 positionToGo, bool isForced = false);
	void attack(shared_ptr<Entity> entityToAttack, bool isForced = false);
	void select(bool doSelect = true);
};