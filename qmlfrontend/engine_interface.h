#ifndef ENGINE_H
#define ENGINE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
#define ENUM_CLASS enum
namespace Engine {
extern "C" {
#else
#define ENUM_CLASS enum
#endif

typedef struct _EngineInstance EngineInstance;

typedef struct {
  uint32_t width;
  uint32_t height;
  uint8_t hedgehogs_number;
  unsigned char* land;
} PreviewInfo;

typedef uint32_t hedgewars_engine_protocol_version_t();
typedef EngineInstance* start_engine_t();
typedef void generate_preview_t(EngineInstance* engine_state,
                                PreviewInfo* preview);
typedef void dispose_preview_t(EngineInstance* engine_state);
typedef void cleanup_t(EngineInstance* engine_state);

typedef void send_ipc_t(EngineInstance* engine_state, uint8_t* buf,
                        size_t size);
typedef size_t read_ipc_t(EngineInstance* engine_state, uint8_t* buf,
                          size_t size);

typedef void setup_current_gl_context_t(EngineInstance* engine_state,
                                        uint16_t width, uint16_t height,
                                        void (*(const char*))());
typedef void render_frame_t(EngineInstance* engine_state);

typedef bool advance_simulation_t(EngineInstance* engine_state, uint32_t ticks);

typedef void move_camera_t(EngineInstance* engine_state, int32_t delta_x,
                           int32_t delta_y);

ENUM_CLASS SimpleEventType{
    SwitchHedgehog, Timer, LongJump, HighJump, Accept, Deny,
};

ENUM_CLASS LongEventType{
    ArrowUp, ArrowDown, ArrowLeft, ArrowRight, Precision, Attack,
};

ENUM_CLASS LongEventState{
    Set,
    Unset,
};

ENUM_CLASS PositionedEventType{
    CursorMove,
    CursorClick,
};

typedef void simple_event_t(EngineInstance* engine_state,
                            SimpleEventType event_type);
typedef void long_event_t(EngineInstance* engine_state,
                          LongEventType event_type, LongEventState state);
typedef void positioned_event_t(EngineInstance* engine_state,
                                PositionedEventType event_type, int32_t x,
                                int32_t y);
#ifdef __cplusplus
}
};
#endif

#endif  // ENGINE_H
