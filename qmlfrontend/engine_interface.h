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

extern hedgewars_engine_protocol_version_t* hedgewars_engine_protocol_version;
extern start_engine_t* start_engine;
extern generate_preview_t* generate_preview;
extern cleanup_t* cleanup;

extern send_ipc_t* send_ipc;
extern read_ipc_t* read_ipc;

extern setup_current_gl_context_t* setup_current_gl_context;
extern render_frame_t* render_frame;
extern advance_simulation_t* advance_simulation;

#ifdef __cplusplus
}
};
#endif

#endif  // ENGINE_H
