#pragma once
#include "Leadwerks.h"
#include "../BaseComponent.h"

using namespace Leadwerks;

class ChangeVisibility : public BaseComponent
{
public: 
    int integervalue = 0;
    float floatvalue = 0.0f;
    bool booleanvalue = false;
    std::shared_ptr<Entity> entityvalue;
    
    ChangeVisibility();

    virtual void Hide();
    virtual void Show();
    virtual std::shared_ptr<Component> Copy();
    virtual std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args);
};