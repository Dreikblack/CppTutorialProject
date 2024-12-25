#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;

class WayPoint : public Component {
protected:
	//another WayPoint's entity, where platform will move to once reaching this one
	//it should be weak pointer for avoiding circular dependency when entities can't be removed from scene because they keep shared pointers to each other
	std::weak_ptr<Entity> nextPoint;
public:
	//wait for command before moving to next WayPoint
	bool doStayOnPoint;
	WayPoint();
	//can be used to specify what should and what should not be copied to new class instance
	shared_ptr<Component> Copy() override;
	//override specifier ensures that the method is virtual and is overriding a virtual function from a base class
	//it means that this class method will be called even if class instance was casted to base class
	//it allows to change class behaviour from base one
	//Start is called when Load() of all components was called already
	void Start() override;
	//will be called on map load
	bool Load(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
	//Can be used to save current component state on map save
	bool Save(table& t, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
	//get next WayPoint's entity
	//const means method change nothing and can be executed in debug to get value
	shared_ptr<Entity> getNextPoint() const;
};