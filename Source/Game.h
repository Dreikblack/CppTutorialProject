#pragma once
#include "UltraEngine.h"
#include "Components/Player/FPSPlayer.h"

using namespace UltraEngine;

class Game : public Object {
protected:
	shared_ptr<Camera> uiCamera;
	shared_ptr<Scene> scene;
	shared_ptr<FPSPlayer> player;
	shared_ptr<Widget> menuPanel;
	Game();
	void init(shared_ptr<Framebuffer> framebuffer, WString mapPath);
public:
	//to show/hide game menu on Esc
	static bool GameMenuButtonCallback(const Event& ev, shared_ptr<Object> extra);
	static std::shared_ptr<Game> create(shared_ptr<Framebuffer> framebuffer, WString mapPath);
	shared_ptr<Interface> ui;
	shared_ptr<World> world;
};