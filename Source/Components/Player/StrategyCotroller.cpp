#include "UltraEngine.h"
#include "StrategyCotroller.h"
#include "../AI/Unit.h"

StrategyCotroller::StrategyCotroller() {
	name = "StrategyCotroller";
}

shared_ptr<Component> StrategyCotroller::Copy() {
	return std::make_shared<StrategyCotroller>(*this);
}

StrategyCotroller::~StrategyCotroller() = default;

void StrategyCotroller::Start() {
	auto entity = GetEntity();
	entity->AddTag("StrategyCotroller");
	Listen(EVENT_MOUSEDOWN, nullptr);
	Listen(EVENT_MOUSEUP, nullptr);
	Listen(EVENT_MOUSEMOVE, nullptr);
	Listen(EVENT_KEYUP, nullptr);
	Listen(EVENT_KEYDOWN, nullptr);
	if (entity->As<Camera>()) {
		cameraWeak = entity->As<Camera>();
	} else {
		for (auto const& cameraEntity : GetEntity()->GetWorld()->GetTaggedEntities("Camera")) {
			cameraWeak = cameraEntity->As<Camera>();
			break;
		}
	}
	// 1/1 size for pixel accuarcy scaling
	unitSelectionBox = CreateSprite(entity->GetWorld(), 1, 1);
	unitSelectionBox->SetColor(0, 0.4f, 0.2, 0.5f);
	unitSelectionBox->SetPosition(0, 0, 0.00001f);
	unitSelectionBox->SetRenderLayers(2);
	unitSelectionBox->SetHidden(true);
	//to make sprite transparent
	auto material = CreateMaterial();
	material->SetShadow(false);
	material->SetTransparent(true);
	material->SetPickMode(false);
	material->SetShaderFamily(LoadShaderFamily("Shaders/Unlit.fam"));
	unitSelectionBox->SetMaterial(material);
}

bool StrategyCotroller::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) {
	Component::Load(properties, binstream, scene, flags, extra);
	if (properties["playerTeam"].is_number()) playerTeam = properties["playerTeam"];
	return true;
}

bool StrategyCotroller::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) {
	Component::Save(properties, binstream, scene, flags, extra);
	properties["playerTeam"] = playerTeam;
	return true;
}

void StrategyCotroller::Update() {
	updateUnitSelectionBox();
}

bool StrategyCotroller::ProcessEvent(const Event& e) {
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
		} else if (e.data == MOUSE_RIGHT) {
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
				} else {
					for (auto const& entityWeak : selectedUnits) {
						auto entityUnit = entityWeak.lock();
						if (entityUnit && entityUnit->GetComponent<Unit>()) {
							entityUnit->GetComponent<Unit>()->goTo(pick.position, true);
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
		} else if (e.data == MOUSE_RIGHT) {

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

void StrategyCotroller::deselectAllUnits() {
	for (auto const& entityWeak : selectedUnits) {
		auto entityUnit = entityWeak.lock();
		if (entityUnit && entityUnit->GetComponent<Unit>()) {
			entityUnit->GetComponent<Unit>()->select(false);
		}
	}
	selectedUnits.clear();
}


void StrategyCotroller::updateUnitSelectionBox() {
	if (!isMouseLeftDown) {
		unitSelectionBox->SetHidden(true);
	} else {
		auto window = ActiveWindow();
		if (window) {
			auto mousePosition = window->GetMousePosition();
			iVec2 unitSelectionBoxPoint2(mousePosition.x, mousePosition.y);
			iVec2 upLeft(Min(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Min(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
			iVec2 downRight(Max(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Max(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
			if ((downRight.x - upLeft.x < 4) || (downRight.y - upLeft.y < 4)) {
				unitSelectionBox->SetHidden(true);
				return;
			}
			unitSelectionBox->SetPosition(upLeft.x, window->GetFramebuffer()->GetSize().height - downRight.y);
			auto width = downRight.x - upLeft.x;
			auto height = downRight.y - upLeft.y;
			unitSelectionBox->SetScale(width, height, 1);
			unitSelectionBox->SetHidden(false);
		}
		
	}
}

bool StrategyCotroller::selectUnitsByBox(shared_ptr<Camera> camera, shared_ptr<Framebuffer> framebuffer, iVec2 unitSelectionBoxPoint2) {
	if (!unitSelectionBox || unitSelectionBox->GetHidden() || !camera || !framebuffer) {
		return false;
	}
	iVec2 upLeft(Min(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Min(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
	iVec2 downRight(Max(unitSelectionBoxPoint1.x, unitSelectionBoxPoint2.x), Max(unitSelectionBoxPoint1.y, unitSelectionBoxPoint2.y));
	auto pick1 = camera->Pick(framebuffer, upLeft.x, upLeft.y, 0, true);
	auto pick2 = camera->Pick(framebuffer, downRight.x, downRight.y, 0, true);

	if (!pick1.success || !pick2.success) {
		return false;
	}
	deselectAllUnits();
	Vec3 positionLower = pick1.position;
	Vec3 positionUpper = pick2.position;
	positionUpper.y = positionUpper.y + selectHeight;
	//visualization
	//float sz = 0.2f;
	//unitSelectionBox1 = CreateBoxBrush(camera->GetWorld(), sz, sz, sz);
	//unitSelectionBox2 = CreateBoxBrush(camera->GetWorld(), sz, sz, sz);
	//unitSelectionBox1->SetPosition(positionLower);
	//unitSelectionBox2->SetPosition(positionUpper);
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
