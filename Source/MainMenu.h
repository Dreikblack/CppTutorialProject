#pragma once
#include "Leadwerks.h"

using namespace UltraEngine;

//Object is convenient class for a parent class due As() - casting, and Self() methods
class MainMenu : public Object {
protected:
	//constructor - you can think about it as a first method that will be called
	//protected in this case because we will use create() method for making a new Manu
	MainMenu();
	//shared_ptr is smart pointer that will destroy object automatically once all pointer of this objects are out of scope
	//in perfect world you need to have maximum only one shared pointer to specific class instance/object as class member, because otherwise object may stay in memory when you don't expect it
	//for cases when you need pointer without keeping an object you can use std::weak_ptr and it's method .lock() to get a shared_ptr for specific code scope
	//2D camera for GUI
	shared_ptr<Camera> uiCamera;
	//Scene is map entities in first place and you need to keep as long as you need to keep map object
	shared_ptr<Scene> scene;
	void init(shared_ptr<Framebuffer> framebuffer);
public:
	static std::shared_ptr<MainMenu> create(shared_ptr<Framebuffer> framebuffer);
	shared_ptr<Interface> ui;
	shared_ptr<World> world;
};