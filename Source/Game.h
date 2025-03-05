#pragma once
#include "Leadwerks.h"
#include "Components/Player/FPSPlayer.h"

using namespace UltraEngine;

class Game : public Object {
protected:
	shared_ptr<Camera> uiCamera;
	shared_ptr<Scene> scene;
	shared_ptr<FPSPlayer> fpsPlayer;
	shared_ptr<Widget> menuPanel;
	shared_ptr<Widget> gameSavedLabel;
	//hide gameSavedLabel on timer
	shared_ptr<Timer> gameSavedLabelTimer;
	vector<shared_ptr<Entity>> prefabCache;
	Game();
	void init(shared_ptr<Framebuffer> framebuffer, WString mapPath);
	//update basic entity properties - position, rotation, tags
	void loadEntity(shared_ptr<Entity> entity, table entityTable);
	void loadGame(table saveTable);
	void saveGame(WString saveName);
	static bool QuickSaveGameCallback(const UltraEngine::Event& ev, shared_ptr<UltraEngine::Object> extra);
	static bool HideGameSavedLabelCallback(const UltraEngine::Event& ev, shared_ptr<UltraEngine::Object> extra);
public:
	//to show/hide game menu on Esc
	static bool GameMenuButtonCallback(const Event& ev, shared_ptr<Object> extra);
	static std::shared_ptr<Game> create(shared_ptr<Framebuffer> framebuffer, WString mapPath);
	//for game loading
	static std::shared_ptr<Game> create(shared_ptr<Framebuffer> framebuffer, table saveTable);
	shared_ptr<Interface> ui;
	shared_ptr<World> world;
};