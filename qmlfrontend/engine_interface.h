#ifndef ENGINE_H
#define ENGINE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
namespace Engine {
extern "C" {
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

#ifdef __cplusplus
}
};
#endif

#endif  // ENGINE_H
