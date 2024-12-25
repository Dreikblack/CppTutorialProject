#include "UltraEngine.h"
#include "BaseComponent.h"

void BaseComponent::Damage(const int amount, shared_ptr<Entity> attacker) {}
void BaseComponent::Kill(shared_ptr<Entity> attacker) {}
void BaseComponent::Use(shared_ptr<Entity> user) {}

bool BaseComponent::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const LoadFlags flags, std::shared_ptr<Object> extra)
{
    return Component::Load(properties, binstream, scene, flags, extra);
}

bool BaseComponent::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Scene> scene, const SaveFlags flags, std::shared_ptr<Object> extra)
{
    return Component::Save(properties, binstream, scene, flags, extra);
}

std::any BaseComponent::CallMethod(shared_ptr<Component> caller, const WString& name, const std::vector<std::any>& args)
{
    return Component::CallMethod(caller, name, args);
}