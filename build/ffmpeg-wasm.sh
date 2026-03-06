#!/bin/bash
# `-o <OUTPUT_FILE_NAME>` must be provided when using this build script.
# ex:
#     bash ffmpeg-wasm.sh -o ffmpeg.js

set -euo pipefail

EXPORT_NAME="createFFmpegCore"

CONF_FLAGS=(
  -I. 
  -I./src/fftools 
  -I$INSTALL_DIR/include 
  -L$INSTALL_DIR/lib 
  -Llibavcodec 
  -Llibavdevice 
  -Llibavfilter 
  -Llibavformat 
  -Llibavutil 
  -Llibpostproc 
  -Llibswresample 
  -Llibswscale 
  -lavcodec 
  -lavdevice 
  -lavfilter 
  -lavformat 
  -lavutil 
#  -lpostproc 
  -lswresample 
  -lswscale 
  -Wno-deprecated-declarations 
  $LDFLAGS 
  -sENVIRONMENT=worker
  -s MALLOC=mimalloc                       # use Microsoft mimalloc
  -sWASM_BIGINT                            # enable big int support
  -sUSE_SDL=2                              # use emscripten SDL2 lib port
  -sSTACK_SIZE=8MB                         # increase stack size to support libopus
  -sMODULARIZE                             # modularized to use as a library
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=1024MB}   # ALLOW_MEMORY_GROWTH is not recommended when using threads, thus we use a large initial memory
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}    # use 32 threads
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB}     # Use just enough memory as memory usage can grow
  -sALLOW_MEMORY_GROWTH
  -sMAXIMUM_MEMORY=4GB
  -sEXPORT_NAME="$EXPORT_NAME"             # required in browser env, so that user can access this module from window object
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js) # exported functions
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js) # exported built-in functions
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js        # extra bindings, contains most of the ffmpeg.wasm javascript code
  # ffmpeg source code
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_demux.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_mux_init.c
  src/fftools/ffmpeg_opt.c
  src/fftools/ffmpeg_sched.c
  src/fftools/ffplay.c
  src/fftools/ffplay_renderer.c
  src/fftools/ffprobe.c
  src/fftools/opt_common.c
  src/fftools/sync_queue.c
  src/fftools/thread_queue.c
  src/fftools/ffmpeg_enc.c
  src/fftools/ffmpeg_dec.c
  src/fftools/graph/graphprint.c
  src/fftools/textformat/avtextformat.c
  src/fftools/textformat/tf_compact.c
  src/fftools/textformat/tf_default.c
  src/fftools/textformat/tf_flat.c
  src/fftools/textformat/tf_ini.c
  src/fftools/textformat/tf_json.c
  src/fftools/textformat/tf_mermaid.c
  src/fftools/textformat/tf_xml.c
  src/fftools/textformat/tw_avio.c
  src/fftools/textformat/tw_buffer.c
  src/fftools/textformat/tw_stdout.c
  src/fftools/resources/resman.c
  src/fftools/resources/graph.css.c
  src/fftools/resources/graph.html.c
)

# Copied from https://github.com/wide-video/ffmpeg-wasm/blob/main/scripts/build-ffmpeg.sh#L11-L17
(cd src/fftools/resources && xxd -n ff_graph_css_data -i graph.css > graph.css.c)
(cd src/fftools/resources && xxd -n ff_graph_html_data -i graph.html > graph.html.c)
sed -i 's/ff_graph_css_data_len/ff_graph_css_len/g' src/fftools/resources/graph.css.c
sed -i 's/ff_graph_html_data_len/ff_graph_html_len/g' src/fftools/resources/graph.html.c


ls -lah src/fftools/resources/
emcc "${CONF_FLAGS[@]}" $@
