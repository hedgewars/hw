#ifndef ENGINE_H
#define ENGINE_H

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

typedef uint32_t protocol_version_t();
typedef EngineInstance* start_engine_t();
typedef void generate_preview_t(EngineInstance* engine_state,
                                PreviewInfo* preview);
typedef void cleanup_t(EngineInstance* engine_state);

extern protocol_version_t* protocol_version;
extern start_engine_t* start_engine;
extern generate_preview_t* generate_preview;
extern cleanup_t* cleanup;

#ifdef __cplusplus
}
};
#endif

#endif  // ENGINE_H
