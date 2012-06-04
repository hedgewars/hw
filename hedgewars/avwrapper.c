
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "libavformat/avformat.h"

static AVFormatContext* g_pContainer;
static AVOutputFormat* g_pFormat;
static AVStream* g_pAStream;
static AVStream* g_pVStream;
static AVFrame* g_pAFrame;
static AVFrame* g_pVFrame;
static AVCodec* g_pACodec;
static AVCodec* g_pVCodec;
static AVCodecContext* g_pAudio;
static AVCodecContext* g_pVideo;

static int g_Width, g_Height, g_Framerate;
static int g_Frequency, g_Channels;

static FILE* g_pSoundFile;
static int16_t* g_pSamples;
static int g_NumSamples;

/*
Initially I wrote code for latest ffmpeg, but on Linux (Ubuntu)
only older version is available from repository. That's why you see here
all of this #if LIBAVCODEC_VERSION_MAJOR < 54.
Actually, it may be possible to remove code for newer version
and use only code for older version.
*/

#if LIBAVCODEC_VERSION_MAJOR < 54
#define OUTBUFFER_SIZE 200000
static uint8_t g_OutBuffer[OUTBUFFER_SIZE];
#endif

// pointer to function from hwengine (uUtils.pas)
static void (*AddFileLogRaw)(const char* pString);

static void FatalError(const char* pFmt, ...)
{
    const char Buffer[1024];
    va_list VaArgs;

    va_start(VaArgs, pFmt);
    vsnprintf(Buffer, 1024, pFmt, VaArgs);
    va_end(VaArgs);

    AddFileLogRaw("Error in av-wrapper: ");
    AddFileLogRaw(Buffer);
    AddFileLogRaw("\n");
    exit(1);
}

// Function to be called from libav for logging.
// Note: libav can call LogCallback from different threads
// (there is mutex in AddFileLogRaw).
static void LogCallback(void* p, int Level, const char* pFmt, va_list VaArgs)
{
    const char Buffer[1024];

    vsnprintf(Buffer, 1024, pFmt, VaArgs);
    AddFileLogRaw(Buffer);
}

static void Log(const char* pFmt, ...)
{
    const char Buffer[1024];
    va_list VaArgs;

    va_start(VaArgs, pFmt);
    vsnprintf(Buffer, 1024, pFmt, VaArgs);
    va_end(VaArgs);

    AddFileLogRaw(Buffer);
}

static void AddAudioStream(enum CodecID codec_id)
{
#if LIBAVCODEC_VERSION_MAJOR >= 54
    g_pAStream = avformat_new_stream(g_pContainer, g_pACodec);
#else
    g_pAStream = av_new_stream(g_pContainer, 1);
#endif
    if(!g_pAStream)
        FatalError("Could not allocate audio stream");
    g_pAStream->id = 1;

    g_pAudio = g_pAStream->codec;
    avcodec_get_context_defaults3(g_pAudio, g_pACodec);
    g_pAudio->codec_id = codec_id;

    // put parameters
    g_pAudio->sample_fmt = AV_SAMPLE_FMT_S16;
 //   pContext->bit_rate = 128000;
    g_pAudio->sample_rate = g_Frequency;
    g_pAudio->channels = g_Channels;

    // some formats want stream headers to be separate
    if (g_pFormat->flags & AVFMT_GLOBALHEADER)
        g_pAudio->flags |= CODEC_FLAG_GLOBAL_HEADER;

    // open it
    if (avcodec_open2(g_pAudio, g_pACodec, NULL) < 0)
        FatalError("Could not open audio codec %s", g_pACodec->long_name);

#if LIBAVCODEC_VERSION_MAJOR >= 54
    if (g_pACodec->capabilities & CODEC_CAP_VARIABLE_FRAME_SIZE)
#else
    if (g_pAudio->frame_size == 0)
#endif
        g_NumSamples = 4096;
    else
        g_NumSamples = g_pAudio->frame_size;
    g_pSamples = (int16_t*)av_malloc(g_NumSamples*g_Channels*sizeof(int16_t));
    g_pAFrame = avcodec_alloc_frame();
    if (!g_pAFrame)
        FatalError("Could not allocate frame");
}

// returns non-zero if there is more sound
static int WriteAudioFrame()
{
    AVPacket Packet = { 0 };
    av_init_packet(&Packet);

    int NumSamples = fread(g_pSamples, 2*g_Channels, g_NumSamples, g_pSoundFile);

#if LIBAVCODEC_VERSION_MAJOR >= 54
    AVFrame* pFrame = NULL;
    if (NumSamples > 0)
    {
        g_pAFrame->nb_samples = NumSamples;
        avcodec_fill_audio_frame(g_pAFrame, g_Channels, AV_SAMPLE_FMT_S16,
                                 (uint8_t*)g_pSamples, NumSamples*2*g_Channels, 1);
        pFrame = g_pAFrame;
    }
    // when NumSamples == 0 we still need to call encode_audio2 to flush
    int got_packet;
    if (avcodec_encode_audio2(g_pAudio, &Packet, pFrame, &got_packet) != 0)
        FatalError("avcodec_encode_audio2 failed");
    if (!got_packet)
        return 0;
#else
    if (NumSamples == 0)
        return 0;
    int BufferSize = OUTBUFFER_SIZE;
    if (g_pAudio->frame_size == 0)
        BufferSize = NumSamples*g_Channels*2;
    Packet.size = avcodec_encode_audio(g_pAudio, g_OutBuffer, BufferSize, g_pSamples);
    if (Packet.size == 0)
        return 1;
    if (g_pAudio->coded_frame && g_pAudio->coded_frame->pts != AV_NOPTS_VALUE)
        Packet.pts = av_rescale_q(g_pAudio->coded_frame->pts, g_pAudio->time_base, g_pAStream->time_base);
    Packet.flags |= AV_PKT_FLAG_KEY;
    Packet.data = g_OutBuffer;
#endif

    // Write the compressed frame to the media file.
    Packet.stream_index = g_pAStream->index;
    if (av_interleaved_write_frame(g_pContainer, &Packet) != 0) 
        FatalError("Error while writing audio frame");
    return 1;
}

// add a video output stream
static void AddVideoStream(enum CodecID codec_id)
{
#if LIBAVCODEC_VERSION_MAJOR >= 54
    g_pVStream = avformat_new_stream(g_pContainer, g_pVCodec);
#else
    g_pVStream = av_new_stream(g_pContainer, 0);
#endif
    if (!g_pVStream)
        FatalError("Could not allocate video stream");

    g_pVideo = g_pVStream->codec;
    avcodec_get_context_defaults3( g_pVideo, g_pVCodec );
    g_pVideo->codec_id = codec_id;

    // put parameters
    // resolution must be a multiple of two
    g_pVideo->width = g_Width;
    g_pVideo->height = g_Height;
    /* time base: this is the fundamental unit of time (in seconds) in terms
       of which frame timestamps are represented. for fixed-fps content,
       timebase should be 1/framerate and timestamp increments should be
       identically 1. */
    g_pVideo->time_base.den = g_Framerate;
    g_pVideo->time_base.num = 1;
    //g_pVideo->gop_size = 12; /* emit one intra frame every twelve frames at most */
    g_pVideo->pix_fmt = PIX_FMT_YUV420P;

    // some formats want stream headers to be separate
    if (g_pFormat->flags & AVFMT_GLOBALHEADER)
        g_pVideo->flags |= CODEC_FLAG_GLOBAL_HEADER;

    AVDictionary* pDict = NULL;
    if (codec_id == CODEC_ID_H264)
    {
       // av_dict_set(&pDict, "tune", "animation", 0);
       // av_dict_set(&pDict, "preset", "veryslow", 0);
       av_dict_set(&pDict, "crf", "20", 0);
    }
    else
    {
        g_pVideo->flags |= CODEC_FLAG_QSCALE;
       // g_pVideo->bit_rate = g_Width*g_Height*g_Framerate/4;
        g_pVideo->global_quality = 15*FF_QP2LAMBDA;
    }

    // open the codec
    if (avcodec_open2(g_pVideo, g_pVCodec, &pDict) < 0)
        FatalError("Could not open video codec %s", g_pVCodec->long_name);

    g_pVFrame = avcodec_alloc_frame();
    if (!g_pVFrame)
        FatalError("Could not allocate frame");

    g_pVFrame->linesize[0] = g_Width;
    g_pVFrame->linesize[1] = g_Width/2;
    g_pVFrame->linesize[2] = g_Width/2;
    g_pVFrame->linesize[3] = 0;
}

static int WriteFrame( AVFrame* pFrame )
{
    double AudioTime, VideoTime;

    // write interleaved audio frame
    if (g_pAStream)
    {
        VideoTime = (double)g_pVStream->pts.val*g_pVStream->time_base.num/g_pVStream->time_base.den;
        do
            AudioTime = (double)g_pAStream->pts.val*g_pAStream->time_base.num/g_pAStream->time_base.den;
        while (AudioTime < VideoTime && WriteAudioFrame());
    }

    AVPacket Packet;
    av_init_packet(&Packet);
    Packet.data = NULL;
    Packet.size = 0;

    g_pVFrame->pts++;
    if (g_pFormat->flags & AVFMT_RAWPICTURE)
    {
        /* raw video case. The API will change slightly in the near
           future for that. */
        Packet.flags |= AV_PKT_FLAG_KEY;
        Packet.stream_index = g_pVStream->index;
        Packet.data = (uint8_t*)pFrame;
        Packet.size = sizeof(AVPicture);

        if (av_interleaved_write_frame(g_pContainer, &Packet) != 0)
            FatalError("Error while writing video frame");
        return 0;
    }
    else
    {
#if LIBAVCODEC_VERSION_MAJOR >= 54
        int got_packet;
        if (avcodec_encode_video2(g_pVideo, &Packet, pFrame, &got_packet) < 0)
            FatalError("avcodec_encode_video2 failed");
        if (!got_packet)
            return 0;

        if (Packet.pts != AV_NOPTS_VALUE)
            Packet.pts = av_rescale_q(Packet.pts, g_pVideo->time_base, g_pVStream->time_base);
        if (Packet.dts != AV_NOPTS_VALUE)
            Packet.dts = av_rescale_q(Packet.dts, g_pVideo->time_base, g_pVStream->time_base);
#else 
        Packet.size = avcodec_encode_video(g_pVideo, g_OutBuffer, OUTBUFFER_SIZE, pFrame);
        if (Packet.size < 0)
            FatalError("avcodec_encode_video failed");
        if (Packet.size == 0)
            return 0;

        if( g_pVideo->coded_frame->pts != AV_NOPTS_VALUE)
            Packet.pts = av_rescale_q(g_pVideo->coded_frame->pts, g_pVideo->time_base, g_pVStream->time_base);
        if( g_pVideo->coded_frame->key_frame )
            Packet.flags |= AV_PKT_FLAG_KEY;
        Packet.data = g_OutBuffer;
#endif
        // write the compressed frame in the media file
        Packet.stream_index = g_pVStream->index;
        if (av_interleaved_write_frame(g_pContainer, &Packet) != 0)
            FatalError("Error while writing video frame");
            
        return 1;
    }
}

void AVWrapper_WriteFrame(uint8_t* pY, uint8_t* pCb, uint8_t* pCr)
{
    g_pVFrame->data[0] = pY;
    g_pVFrame->data[1] = pCb;
    g_pVFrame->data[2] = pCr;
    WriteFrame(g_pVFrame);
}

void AVWrapper_GetList()
{
    // initialize libav and register all codecs and formats
    av_register_all();

#if 0
    AVOutputFormat* pFormat = NULL;
    while (pFormat = av_oformat_next(pFormat))
    {
        Log("%s; %s; %s;\n", pFormat->name, pFormat->long_name, pFormat->mime_type);
        
        AVCodec* pCodec = NULL;
        while (pCodec = av_codec_next(pCodec))
        {
            if (!av_codec_is_encoder(pCodec))
                continue;
            if (avformat_query_codec(pFormat, pCodec->id, FF_COMPLIANCE_NORMAL) != 1)
                continue;
            if (pCodec->type = AVMEDIA_TYPE_VIDEO)
            {
                if (pCodec->supported_framerate != NULL)
                    continue;
                Log("    Video: %s; %s;\n", pCodec->name, pCodec->long_name);
            }
            if (pCodec->type = AVMEDIA_TYPE_AUDIO)
            {
               /* if (pCodec->supported_samplerates == NULL)
                    continue;
                int i;
                for(i = 0; i <)
                    supported_samplerates*/
                Log("    Audio: %s; %s;\n", pCodec->name, pCodec->long_name);
            }
        }
   /*     struct AVCodecTag** pTags = pCur->codec_tag;
        int i;
        for (i = 0; ; i++)
        {
            enum CodecID id = av_codec_get_id(pTags, i);
            if (id == CODEC_ID_NONE)
                break;
            AVCodec* pCodec = avcodec_find_encoder(id);
            Log("    %i: %s; %s;\n", id, pCodec->name, pCodec->long_name);
        }*/
    }
#endif
}

void AVWrapper_Init(void (*pAddFileLogRaw)(const char*), const char* pFilename, const char* pSoundFile, int Width, int Height, int Framerate, int Frequency, int Channels)
{    
    AddFileLogRaw = pAddFileLogRaw;
    av_log_set_callback( &LogCallback );

    g_Width = Width;
    g_Height = Height;
    g_Framerate = Framerate;
    g_Frequency = Frequency;
    g_Channels = Channels;

    // initialize libav and register all codecs and formats
    av_register_all();
    
    AVWrapper_GetList();

    // allocate the output media context
#if LIBAVCODEC_VERSION_MAJOR >= 54
    avformat_alloc_output_context2(&g_pContainer, NULL, "mp4", pFilename);
#else
    g_pFormat = av_guess_format(NULL, pFilename, NULL);
    if (!g_pFormat)
        FatalError("guess_format");

    // allocate the output media context
    g_pContainer = avformat_alloc_context();
    if (g_pContainer)
    {
        g_pContainer->oformat = g_pFormat;
        snprintf(g_pContainer->filename, sizeof(g_pContainer->filename), "%s", pFilename);
    }
#endif
    if (!g_pContainer)
        FatalError("Could not allocate output context");

    g_pFormat = g_pContainer->oformat;

    enum CodecID VideoCodecID = g_pFormat->video_codec;//CODEC_ID_H264;
    enum CodecID AudioCodecID = g_pFormat->audio_codec;

    g_pVStream = NULL;
    g_pAStream = NULL;
    if (VideoCodecID != CODEC_ID_NONE)
    {
        g_pVCodec = avcodec_find_encoder(VideoCodecID);
        if (!g_pVCodec)
            FatalError("Video codec not found");
        AddVideoStream(VideoCodecID);
    }

    if (AudioCodecID != CODEC_ID_NONE)
    {
        g_pACodec = avcodec_find_encoder(AudioCodecID);
        if (!g_pACodec)
            FatalError("Audio codec not found");
        AddAudioStream(AudioCodecID);
    }

    if (g_pAStream)
    {
        g_pSoundFile = fopen(pSoundFile, "rb");
        if (!g_pSoundFile)
            FatalError("Could not open %s", pSoundFile);
    }

    // write format info to log
    av_dump_format(g_pContainer, 0, pFilename, 1);

    // open the output file, if needed
    if (!(g_pFormat->flags & AVFMT_NOFILE))
    {
        if (avio_open(&g_pContainer->pb, pFilename, AVIO_FLAG_WRITE) < 0)
            FatalError("Could not open output file (%s)", pFilename);
    }

    // write the stream header, if any
    avformat_write_header(g_pContainer, NULL);
    g_pVFrame->pts = -1;
}

void AVWrapper_Close()
{
    // output buffered frames
    if (g_pVCodec->capabilities & CODEC_CAP_DELAY)
        while( WriteFrame(NULL) );
    // output any remaining audio
    while( WriteAudioFrame() );

    // write the trailer, if any.
    av_write_trailer(g_pContainer);

    // close each codec
    if( g_pVStream )
    {
        avcodec_close(g_pVStream->codec);
        av_free(g_pVFrame);
    }
    if( g_pAStream )
    {
        avcodec_close(g_pAStream->codec);
        av_free(g_pAFrame);
        av_free(g_pSamples);
        fclose(g_pSoundFile);
    }

    // free the streams
    int i;
    for (i = 0; i < g_pContainer->nb_streams; i++)
    {
        av_freep(&g_pContainer->streams[i]->codec);
        av_freep(&g_pContainer->streams[i]);
    }

    // close the output file
    if (!(g_pFormat->flags & AVFMT_NOFILE))
        avio_close(g_pContainer->pb);

    // free the stream 
    av_free(g_pContainer);
}
