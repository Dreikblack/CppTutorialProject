#pragma once
#include "Leadwerks.h"

using namespace UltraEngine;


class StrategyController : public Component {
protected:
	vector<std::weak_ptr<Entity>> selectedUnits;
	//Control key state
	bool isControlDown = false;
	int playerTeam = 1;
	std::weak_ptr<Camera> cameraWeak;
	shared_ptr<Sprite> unitSelectionBox;
	//first mouse position when Mouse Left was pressed
	iVec2 unitSelectionBoxPoint1;
	//height of selection box
	float selectHeight = 4;
	//mouse left button state
	bool isMouseLeftDown = false;
	//draw or hide selection box
	void updateUnitSelectionBox();
	bool selectUnitsByBox(shared_ptr<Camera> camera, shared_ptr<Framebuffer> framebuffer, iVec2 unitSelectionBoxPoint2);
	void deselectAllUnits();
	static bool RayFilter(shared_ptr<Entity> entity, shared_ptr<Object> extra);
public:
	StrategyController();
	~StrategyController() override;
	shared_ptr<Component> Copy() override;
	bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	void Update() override;
	void Start() override;
	bool ProcessEvent(const Event& e) override;
};