#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class ChangeEmission : public BaseComponent
{
public: 
    bool recursive = false;
    Vec3 color0;
    Vec3 color1;
    Vec3 color2;

    ChangeEmission();

    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
	virtual bool Load(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra);
    virtual bool Save(table& properties, std::shared_ptr<Stream> binstream, std::shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra);
    virtual std::shared_ptr<Component> Copy();
};