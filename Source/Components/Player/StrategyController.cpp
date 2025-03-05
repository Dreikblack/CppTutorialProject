#include "Leadwerks.h"
#include "StrategyController.h"
#include "../AI/Unit.h"

StrategyController::StrategyController() {
	name = "StrategyController";
}

shared_ptr<Component> StrategyController::Copy() {
	return std::make_shared<StrategyController>(*this);
}

StrategyController::~StrategyController() = default;

void StrategyController::Start() {
	auto entity = GetEntity();
	entity->AddTag("StrategyController");
	//for custom save/load system
	entity->AddTag("Save");
	//Listen() needed for calling ProcessEvent() in component when event happen
	Listen(EVENT_MOUSEDOWN, nullptr);
	Listen(EVENT_MOUSEUP, nullptr);
	Listen(EVENT_MOUSEMOVE, nullptr);
	Listen(EVENT_KEYUP, nullptr);
	Listen(EVENT_KEYDOWN, nullptr);
	//optimal would be setting component to a camera
	if (entity->As<Camera>()) {
		cameraWeak = entity->As<Camera>();
	} else {
		//otherwise let's get it by tag
		for (auto const& cameraEntity : GetEntity()->GetWorld()->GetTaggedEntities("Camera")) {
			cameraWeak = cameraEntity->As<Camera>();
			break;
		}
	}
	// 1/1 size for pixel accuarcy scaling
	unitSelectionBox = CreateSprite(entity->GetWorld(), 1, 1);
	//transparent green color
	unitSelectionBox->SetColor(0, 0.4f, 0.2, 0.5f);
	unitSelectionBox->SetPosition(0, 0, 0.00001f);
	unitSelectionBox->SetRenderLayers(2);
	unitSelectionBox->SetHidden(true);
	//to make sprite transparent
	auto material = CreateMaterial();
	material->SetShadow(false);
	material->SetTransparent(true);
	material->SetPickMode(false);
	//Unlit removes any effect that would light draw on material
	material->SetShaderFamily(LoadShaderFamily("Shaders/Unlit.fam"));
	unitSelectionBox->SetMaterial(material);
}

bool StrategyController::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	Component::Load(properties, binstream, scene, flags, extra);
	if (properties["playerTeam"].is_number()) playerTeam = properties["playerTeam"];
	selectedUnits.clear();
	if (properties["selectedUnits"].is_array()) {
		for (int i = 0; i < properties["selectedUnits"].size(); i++) {
			auto unit = scene->GetEntity(properties["selectedUnits"][i]);
			if (unit) {
				selectedUnits.push_back(unit);
			}
		}
	}
	return true;
}

bool StrategyController::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	Component::Save(properties, binstream, scene, flags, extra);
	properties["playerTeam"] = playerTeam;
	properties["selectedUnits"] = {};
	int index = 0;
	for (auto const& selectedUnitWeak : selectedUnits) {
		auto selectedUnit = selectedUnitWeak.lock();
		if (selectedUnit) {
			properties["selectedUnits"][index] = selectedUnit->GetUuid();
			index++;
		}
	}
	return true;
}

void StrategyController::Update() {
	updateUnitSelectionBox();
}

bool StrategyController::ProcessEvent(const Event& e) {
	auto window = ActiveWindow();
	if (!window) {
		return true;
	}
	auto mousePosition = window->GetMousePosition();
	auto camera = cameraWeak.lock();
	switch (e.id) {
	case EVENT_MOUSEDOWN:
		if (!camera) {
			break;
		}
		if (e.data == MOUSE_LEFT) {
			unitSelectionBoxPoint1 = iVec2(mousePosition.x, mousePosition.y);
			isMouseLeftDown = true;
		//move or attack on Right Click
		} else if (e.data == MOUSE_RIGHT) {
			//getting entity under cursor
			auto pick = camera->Pick(window->GetFramebuffer(), mousePosition.x, mousePosition.y, 0, true);
			if (pick.success && pick.entity) {
				auto unit = pick.entity->GetComponent<Unit>();
				if (unit && unit->isAlive() && unit->team != playerTeam) {
					for (auto const& entityWeak : selectedUnits) {
						auto entityUnit = entityWeak.lock();
						if (entityUnit && entityUnit->GetComponent<Unit>()) {
							entityUnit->GetComponent<Unit>()->attack(pick.entity, true);
						}
					}
				} else if (!selectedUnits.empty()) {
					auto flag = LoadPrefab(camera->GetWorld(), "Prefabs/FlagWayPoint.pfb");
					if (flag) {
						flag->SetPosition(pick.position);
					}
					for (auto const& entityWeak : selectedUnits) {
						auto entityUnit = entityWeak.lock();
						if (entityUnit && entityUnit->GetComponent<Unit>()) {
							if (flag) {
								entityUnit->GetComponent<Unit>()->goTo(flag, true);
							} else {
								entityUnit->GetComponent<Unit>()->goTo(pick.position, true);
							}
						}
					}
				}
			}
		}
		break;
	case EVENT_MOUSEUP:
		if (!camera) {
			break;
		}
		//unit selection on Left Click
		if (e.data == MOUSE_LEFT) {
			if (!selectUnitsByBox(camera, window->GetFramebuffer(), iVec2(mousePosition.x, mousePosition.y))) {
				auto pick = camera->Pick(window->GetFramebuffer(), mousePosition.x, mousePosition.y, 0, true);
				if (pick.success && pick.entity) {
					auto unit = pick.entity->GetComponent<Unit>();
					if (unit && unit->isPlayer && unit->isAlive()) {
						if (!isControlDown) {
							deselectAllUnits();
						}
						selectedUnits.push_back(pick.entity);
						unit->select();
					} else {
						deselectAllUnits();
					}
				} else {
					deselectAllUnits();
				}
			}
			isMouseLeftDown = false;
		}
		break;
	case EVENT_MOUSEMOVE:
		break;
		
	case EVENT_KEYUP:
		if (e.data == KEY_CONTROL) {
			isControlDown = false;
		}
		break;
	case EVENT_KEYDOWN:
		if (e.data == KEY_CONTROL) {
			isControlDown = true;
		}
		break;

	}
	return true;
}

void StrategyController::deselectAllUnits() {
	for (auto const& entityWeak : selectedUnits) {
		auto entityUnit = entityWeak.lock();
		if (entityUnit && entityUnit->GetComponent<Unit>()) {
			entityUnit->GetComponent<Unit>()->select(false);
		}
	}
	selectedUnits.clear();
}

void StrategyController::updateUnitSelectionBox() {
	if (!isMouseLeftDown) {
		unitSelectionBox->SetHidden(true);
	} else {
		auto window = ActiveWindow();
		if (window) {
			auto mousePosition = window->GetMousePosition();
			iVec2 unitSelectionBoxPoint2(mousePosition.x, mousePosition.y);
			iVec2 upLeft(Min(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Min(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
			iVec2 downRight(Max(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Max(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
			//don't show Selection Box if it's only few pixels and could be single click to select unit
			if ((downRight.x - upLeft.x < 4) || (downRight.y - upLeft.y < 4)) {
				unitSelectionBox->SetHidden(true);
				return;
			}
			unitSelectionBox->SetPosition(upLeft.x, window->GetFramebuffer()->GetSize().height - downRight.y);
			auto width = downRight.x - upLeft.x;
			auto height = downRight.y - upLeft.y;
			//changing sprite size via scale, just size is readonly
			unitSelectionBox->SetScale(width, height, 1);
			unitSelectionBox->SetHidden(false);
		}
		
	}
}

bool StrategyController::selectUnitsByBox(shared_ptr<Camera> camera, shared_ptr<Framebuffer> framebuffer, iVec2 unitSelectionBoxPoint2) {
	if (!unitSelectionBox || unitSelectionBox->GetHidden() || !camera || !framebuffer) {
		return false;
	}
	iVec2 upLeft(Min(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Min(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
	iVec2 downRight(Max(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Max(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
	auto pick1 = camera->Pick(framebuffer, upLeft.x, upLeft.y, 0, true, RayFilter);
	auto pick2 = camera->Pick(framebuffer, downRight.x, downRight.y, 0, true, RayFilter);

	if (!pick1.success || !pick2.success) {
		return false;
	}
	deselectAllUnits();
	//first param GetEntitiesInArea should has lower coordinates than second
	Vec3 positionLower = Vec3(Min(pick1.position.x, pick2.position.x), Min(pick1.position.y, pick2.position.y), Min(pick1.position.z, pick2.position.z));
	Vec3 positionUpper = Vec3(Max(pick1.position.x, pick2.position.x), Max(pick1.position.y, pick2.position.y), Max(pick1.position.z, pick2.position.z));
	positionUpper.y = positionUpper.y + selectHeight;
	for (auto const& foundEntity : camera->GetWorld()->GetEntitiesInArea(positionLower, positionUpper)) {
		auto foundUnit = foundEntity->GetComponent<Unit>();
		//targets are only alive enemy units
		if (!foundUnit || !foundUnit->isAlive() || !foundUnit->isPlayer || foundUnit->team != playerTeam) {
			continue;
		}
		selectedUnits.push_back(foundUnit->GetEntity());
		foundUnit->select();
	}
	return true;
}

bool StrategyController::RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra) {
	shared_ptr<Unit> pickedUnit = entity->GetComponent<Unit>();
	//skip if it's unit
	return pickedUnit == nullptr;
}

