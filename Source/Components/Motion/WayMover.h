#pragma once
#include "UltraEngine.h"

using namespace UltraEngine;

class WayMover : public Component {
protected:
    float moveSpeed;
    bool isMoving;
    std::weak_ptr<Entity> nextPoint;
    bool doDeleteAfterMovement;
    //need scene pointer to remove entity if doDeleteAfterMovement true
    //should be weak_ptr to avoid circular dependency
    std::weak_ptr<Map> sceneWeak;
public:
    WayMover();
    std::shared_ptr<Component> Copy() override;
    bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags, shared_ptr<Object> extra) override;
    bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags, shared_ptr<Object> extra) override;
    //CallMethod procceds input signals
    std::any CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args) override;
    void Update() override;
    //called when reaching next WayPoint
    void moveEnd();
};