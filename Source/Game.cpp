#include "UltraEngine.h"
#include "Game.h"
#include "CustomEvents.h"

Game::Game() = default;

std::shared_ptr<Game> Game::create(shared_ptr<Framebuffer> framebuffer, WString mapPath) {
	struct Struct : public Game {};
	auto instance = std::make_shared<Struct>();
	instance->init(framebuffer, mapPath);
	return instance;
}

std::shared_ptr<Game> Game::create(shared_ptr<Framebuffer> framebuffer, table saveTable) {
	struct Struct : public Game {};
	auto instance = std::make_shared<Struct>();
	std::string mapName = saveTable["MapPath"];
	instance->init(framebuffer, WString(mapName));
	instance->loadGame(saveTable);
	return instance;
}

bool Game::GameMenuButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	if (KEY_ESCAPE == ev.data && extra) {
		auto game = extra->As<Game>();
		bool isHidden = game->menuPanel->GetHidden();
		game->menuPanel->SetHidden(!isHidden);
		if (game->fpsPlayer) {
			//we can get a game window anywhere, but take in mind that it will return nullptr, if window is not active ;)
			auto window = ActiveWindow();
			//checking just in case if we actually got a window
			if (window) {
				//hiding cursor when hiding a menu and vice versa
				window->SetCursor(isHidden ? CURSOR_DEFAULT : CURSOR_NONE);
			}
			game->fpsPlayer->doResetMousePosition = !isHidden;
		}
		
		//If the callback function returns false no more callbacks will be executed and no event will be added to the event queue.
		//to avoid double call
		return false;
	}
	return true;
}

static bool MainMenuButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	EmitEvent(EVENT_MAIN_MENU);
	return true;
}

static bool ExitButtonCallback(const Event& ev, shared_ptr<Object> extra) {
	exit(0);
	return true;
}

void Game::init(shared_ptr<Framebuffer> framebuffer, WString mapPath) {
	world = CreateWorld();
	scene = LoadMap(world, mapPath);
	for (auto const& entity : scene->entities) {
		auto foundPlayer = entity->GetComponent<FPSPlayer>();
		if (foundPlayer) {
			fpsPlayer = foundPlayer;
			break;
		}
	}
	auto font = LoadFont("Fonts/arial.ttf");
	//Create user interface for game menu
	auto frameSize = framebuffer->GetSize();
	ui = CreateInterface(world, font, frameSize);
	ui->SetRenderLayers(2);
	ui->root->SetColor(0.0f, 0.0f, 0.0f, 0.0f);
	uiCamera = CreateCamera(world, PROJECTION_ORTHOGRAPHIC);
	uiCamera->SetPosition(float(frameSize.x) * 0.5f, float(frameSize.y) * 0.5f, 0);
	uiCamera->SetRenderLayers(2);
	uiCamera->SetClearMode(CLEAR_DEPTH);
	//widgets are stays without extra shared pointers because parent widet, ui->root in this case, keep them
	//to remove widget you should do widget->SetParent(nullptr)
	menuPanel = CreatePanel(frameSize.width / 2 - 150, frameSize.height / 2 - 300 / 2, 300, 250, ui->root);
	gameSavedLabel = CreateLabel("GAME SAVED", frameSize.width / 2 - 100, 50, 200, 30, ui->root);
	gameSavedLabel->SetFontScale(2.0f);
	gameSavedLabel->SetHidden(true);
	auto menuButton = CreateButton("Main menu", 50, 50, 200, 50, menuPanel);
	ListenEvent(EVENT_WIDGETACTION, menuButton, MainMenuButtonCallback);
	auto exitButton = CreateButton("Exit", 50, 150, 200, 50, menuPanel);
	ListenEvent(EVENT_WIDGETACTION, exitButton, ExitButtonCallback, nullptr);
	//we don't need game menu on screen while playing
	menuPanel->SetHidden(true);
	//and we will need it once hitting Esc button
	ListenEvent(EVENT_KEYUP, nullptr, GameMenuButtonCallback, Self());
	//take in mind that extra param will be kept as shared_ptr in callback ^
	ListenEvent(EVENT_KEYUP, nullptr, QuickSaveGameCallback, Self());
}

void Game::loadEntity(shared_ptr<Entity> entity, table entityTable) {
	if (entityTable["position"].is_array() && entityTable["position"].size() == 3) {
		entity->SetPosition(entityTable["position"][0], entityTable["position"][1], entityTable["position"][2], true);
	}
	if (entityTable["rotation"].is_array() && entityTable["rotation"].size() == 3) {
		entity->SetRotation(entityTable["rotation"][0], entityTable["rotation"][1], entityTable["rotation"][2], true);
	}
	if (entityTable["tags"].is_array()) {
		for (int i = 0; i < entityTable["tags"].size(); i++) {
			entity->AddTag(std::string(entityTable["tags"][i]));
		}
	}
}

void Game::loadGame(table saveTable) {
	//old-new entity id
	vector<std::pair<String, String>> uuids;
	std::set<String> newEntities;
	//entites that was not in scene will be deleted once Components will be loaded and gets needed entities
	std::set<shared_ptr<Entity>> entitiesToRemoveFromScene;
	//iterating std::map by key (uuid) and value (entityTable) instead of pair
	for (auto& [uuid, entityTable] : saveTable["SavedEntities"]) {
		auto entity = scene->GetEntity(uuid);
		//load properties for saved entity that was initially on map
		if (entity) {
			loadEntity(entity, entityTable);
		} else if (entityTable["prefabPath"].is_string()) {
			//spawn saved entity that was not initially on map
			auto spawnedEntity = LoadPrefab(world, String(entityTable["prefabPath"]));
			if (!spawnedEntity) {
				continue;
			}
			scene->AddEntity(spawnedEntity);
			if (entityTable["isInScene"].is_boolean() && !entityTable["isInScene"]) {
				entitiesToRemoveFromScene.insert(spawnedEntity);
			}
			loadEntity(spawnedEntity, entityTable);
			uuids.push_back(std::pair(uuid, spawnedEntity->GetUuid()));
			newEntities.insert(spawnedEntity->GetUuid());
		}
	}
	//delete not saved entities
	for (auto const& entity : world->GetTaggedEntities("Save")) {
		//does newEntities containes curent entity
		if (newEntities.find(entity->GetUuid()) != newEntities.end()) {
			//skip new entity
			continue;
		}
		//if supposed to be saved and was not due being removed when save was made then remove it from scene
		table entityTable = saveTable["SavedEntities"][entity->GetUuid()];
		if (entityTable.empty()) {
			scene->RemoveEntity(entity);
		}
	}
	auto saveString = String(saveTable.to_json());
	for (auto const& [oldUuid, newUuid] : uuids) {
		saveString = saveString.Replace(oldUuid, newUuid);
	}
	saveTable = ParseJson(saveString);
	for (auto const& entity : world->GetTaggedEntities("Save")) {
		auto& entityTable = saveTable["SavedEntities"][entity->GetUuid()];
		for (auto const& component : entity->components) {
			component->Load(entityTable, nullptr, scene, LOAD_DEFAULT, nullptr);
		}
	}
	for (auto const& entity : world->GetTaggedEntities("Save")) {
		for (auto const& component : entity->components) {
			component->Start();
		}	
	}
	for (auto const& entity : entitiesToRemoveFromScene) {
		scene->RemoveEntity(entity);
	}
}

void Game::saveGame(WString saveName) {
	table saveTable;
	saveTable["MapPath"] = RelativePath(scene->path).ToUtf8String();
	saveTable["SavedEntities"] = {};
	for (auto const& entity : world->GetTaggedEntities("Save")) {
		table entityTable;
		for (auto const& component : entity->components) {
			component->Save(entityTable, nullptr, scene, SAVE_DEFAULT, nullptr);
		}
		//just to make save file more readable
		if (!entity->name.empty()) {
			entityTable["name"] = entity->name.ToUtf8String();
		}
		//saving position and rotation of entity to restore them in Load
		auto position = entity->GetPosition(true);
		entityTable["position"] = {};
		entityTable["position"][0] = position.x;
		entityTable["position"][1] = position.y;
		entityTable["position"][2] = position.z;
		auto rotation = entity->GetRotation(true);
		entityTable["rotation"] = {};
		entityTable["rotation"][0] = rotation.x;
		entityTable["rotation"][1] = rotation.y;
		entityTable["rotation"][2] = rotation.z;
		entityTable["tags"] = {};
		entityTable["isInScene"] = scene->GetEntity(entity->GetUuid()) ? true : false;
		int tagIndex = 0;
		for (auto& tag : entity->tags) {
			entityTable["tags"][tagIndex] = tag.ToUtf8String();
			tagIndex++;
		}
		//save prefab path to be able restore entity if it was added to scene later as prefab
		auto prefab = entity->GetPrefab();
		if (prefab) {
			entityTable["prefabPath"] = RelativePath(prefab->GetPath()).ToUtf8String();
		}
		//using entity id as key for its properties
		saveTable["SavedEntities"][entity->GetUuid()] = entityTable;
	}
	SaveTable(saveTable, saveName);
	gameSavedLabel->SetHidden(false);
	gameSavedLabelTimer = UltraEngine::CreateTimer(2000);
	ListenEvent(EVENT_TIMERTICK, gameSavedLabelTimer, HideGameSavedLabelCallback, Self());
}

bool Game::QuickSaveGameCallback(const UltraEngine::Event& ev, shared_ptr<UltraEngine::Object> extra) {
	if (KEY_F5 == ev.data && extra) {
		auto game = extra->As<Game>();
		game->saveGame("QuickSave.save");
	}
	return true;
}

bool Game::HideGameSavedLabelCallback(const UltraEngine::Event& ev, shared_ptr<UltraEngine::Object> extra) {
	if (extra && extra->As<Game>()) {
		auto game = extra->As<Game>();
		game->gameSavedLabel->SetHidden(true);
		game->gameSavedLabelTimer->Stop();
		game->gameSavedLabelTimer = nullptr;
	}
	return false;
}
