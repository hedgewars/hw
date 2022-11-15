#ifndef ENGINE_H
#define ENGINE_H

#include <stddef.h>
#include <stdint.h>

#include "../rust/lib-hedgewars-engine/target/lib-hedgewars-engine.hpp"

#ifndef Q_NAMESPACE
#define Q_NAMESPACE
#endif

#ifndef Q_ENUM_NS
#define Q_ENUM_NS(x)
#endif

#ifndef Q_DECLARE_METATYPE
#define Q_DECLARE_METATYPE(x)
#endif

namespace Engine {
extern "C" {

using EngineInstance = hwengine::EngineInstance;
using PreviewInfo = hwengine::PreviewInfo;

using hedgewars_engine_protocol_version_t =
    decltype(hwengine::hedgewars_engine_protocol_version);

using start_engine_t = decltype(hwengine::start_engine);
using generate_preview_t = decltype(hwengine::generate_preview);
using dispose_preview_t = decltype(hwengine::dispose_preview);
using cleanup_t = decltype(hwengine::cleanup);
using send_ipc_t = decltype(hwengine::send_ipc);
using read_ipc_t = decltype(hwengine::read_ipc);
using setup_current_gl_context_t = decltype(hwengine::setup_current_gl_context);
using render_frame_t = decltype(hwengine::render_frame);
using advance_simulation_t = decltype(hwengine::advance_simulation);
using move_camera_t = decltype(hwengine::move_camera);

using simple_event_t = decltype(hwengine::simple_event);
using long_event_t = decltype(hwengine::long_event);
using positioned_event_t = decltype(hwengine::positioned_event);

using SimpleEventType = hwengine::SimpleEventType;
using LongEventType = hwengine::LongEventType;
using LongEventState = hwengine::LongEventState;
using PositionedEventType = hwengine::PositionedEventType;

}  // extern "C"

Q_NAMESPACE

Q_ENUM_NS(SimpleEventType)
Q_ENUM_NS(LongEventType)
Q_ENUM_NS(LongEventState)
Q_ENUM_NS(PositionedEventType)

};  // namespace

Q_DECLARE_METATYPE(Engine::SimpleEventType)
Q_DECLARE_METATYPE(Engine::LongEventType)
Q_DECLARE_METATYPE(Engine::LongEventState)
Q_DECLARE_METATYPE(Engine::PositionedEventType)

#endif  // ENGINE_H
