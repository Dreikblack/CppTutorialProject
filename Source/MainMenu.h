#pragma once
#include "Leadwerks.h"

using namespace Leadwerks;

//Object is convenient class for a parent class due As() - casting, and Self() methods
class MainMenu : public Object {
protected:
	//constructor - you can think about it as a first method that will be called
	//protected in this case because we will use create() method for making a new Manu
	MainMenu();
	//Scene is map entities in first place and you need to keep as long as you need to keep map object
	shared_ptr<Scene> scene;
	void init(shared_ptr<Framebuffer> framebuffer);
public:
	static std::shared_ptr<MainMenu> create(shared_ptr<Framebuffer> framebuffer);
	shared_ptr<Interface> ui;
	shared_ptr<World> world;
};