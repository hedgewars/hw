/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "LibavInteraction.h"

#if VIDEOREC
extern "C"
{
#include "libavformat/avformat.h"
}

#include <QVector>
#include <QList>
#include <QComboBox>

#include "HWApplication.h"

#if LIBAVCODEC_VERSION_INT >= AV_VERSION_INT(54, 25, 0)
#define CodecID AVCodecID
#endif

struct Codec
{
    CodecID id;
    bool isAudio;
    QString shortName; // used for identification
    QString longName; // used for displaying to user
    bool isRecomended;
};

struct Format
{
    QString shortName;
    QString longName;
    bool isRecomended;
    QString extension;
    QVector<Codec*> codecs;
};

QList<Codec> codecs;
QMap<QString,Format> formats;

// test if given format supports given codec
bool FormatQueryCodec(AVOutputFormat *ofmt, enum CodecID codec_id)
{
#if LIBAVFORMAT_VERSION_MAJOR >= 54
    return avformat_query_codec(ofmt, codec_id, FF_COMPLIANCE_NORMAL) == 1;
#else
    if (ofmt->codec_tag)
        return !!av_codec_get_tag(ofmt->codec_tag, codec_id);
    return codec_id == ofmt->video_codec || codec_id == ofmt->audio_codec;
#endif
}

LibavInteraction::LibavInteraction() : QObject()
{
    // initialize libav and register all codecs and formats
    av_register_all();

    // get list of all codecs
    AVCodec* pCodec = NULL;
    while ((pCodec = av_codec_next(pCodec)))
    {
#if LIBAVCODEC_VERSION_MAJOR >= 54
        if (!av_codec_is_encoder(pCodec))
#else
        if (!pCodec->encode)
#endif
            continue;

        if (pCodec->type != AVMEDIA_TYPE_VIDEO && pCodec->type != AVMEDIA_TYPE_AUDIO)
            continue;

        // this encoders seems to be buggy
        if (strcmp(pCodec->name, "rv10") == 0 || strcmp(pCodec->name, "rv20") == 0)
            continue;

        // doesn't support stereo sound
        if (strcmp(pCodec->name, "real_144") == 0)
            continue;

        if (!pCodec->long_name || strlen(pCodec->long_name) == 0)
            continue;

        if (pCodec->type == AVMEDIA_TYPE_VIDEO)
        {
            if (pCodec->supported_framerates != NULL)
                continue;

            // check if codec supports yuv 4:2:0 format
            if (!pCodec->pix_fmts)
                continue;
            bool yuv420Supported = false;
            for (const AVPixelFormat* pfmt = pCodec->pix_fmts; *pfmt != -1; pfmt++)
                if (*pfmt == AV_PIX_FMT_YUV420P)
                {
                    yuv420Supported = true;
                    break;
                }
            if (!yuv420Supported)
                continue;
        }
        if (pCodec->type == AVMEDIA_TYPE_AUDIO)
        {
            // check if codec supports signed 16-bit format
            if (!pCodec->sample_fmts)
                continue;
            bool s16Supported = false;
            for (const AVSampleFormat* pfmt = pCodec->sample_fmts; *pfmt != -1; pfmt++)
                if (*pfmt == AV_SAMPLE_FMT_S16)
                {
                    s16Supported = true;
                    break;
                }
            if (!s16Supported)
                continue;
        }
        // add codec to list of codecs
        codecs.push_back(Codec());
        Codec & codec = codecs.back();
        codec.id = pCodec->id;
        codec.isAudio = pCodec->type == AVMEDIA_TYPE_AUDIO;
        codec.shortName = pCodec->name;
        codec.longName = pCodec->long_name;

        codec.isRecomended = false;
        if (strcmp(pCodec->name, "libx264") == 0)
        {
            codec.longName = "H.264/MPEG-4 Part 10 AVC (x264)";
            codec.isRecomended = true;
        }
        else if (strcmp(pCodec->name, "libxvid") == 0)
        {
            codec.longName = "MPEG-4 Part 2 (Xvid)";
            codec.isRecomended = true;
        }
        else if (strcmp(pCodec->name, "libmp3lame") == 0)
        {
            codec.longName = "MP3 (MPEG audio layer 3) (LAME)";
            codec.isRecomended = true;
        }
        else
            codec.longName = pCodec->long_name;

        if (strcmp(pCodec->name, "mpeg4") == 0 || strcmp(pCodec->name, "ac3_fixed") == 0)
            codec.isRecomended = true;

        // FIXME: remove next line
        //codec.longName += QString(" (%1)").arg(codec.shortName);
    }

    // get list of all formats
    AVOutputFormat* pFormat = NULL;
    while ((pFormat = av_oformat_next(pFormat)))
    {
        if (!pFormat->extensions)
            continue;

        // skip some strange formats to not confuse users
        if (strstr(pFormat->long_name, "raw"))
            continue;

        Format format;
        bool hasVideoCodec = false;
        for (QList<Codec>::iterator codec = codecs.begin(); codec != codecs.end(); ++codec)
        {
            if (!FormatQueryCodec(pFormat, codec->id))
                continue;
            format.codecs.push_back(&*codec);
            if (!codec->isAudio)
                hasVideoCodec = true;
        }
        if (!hasVideoCodec)
            continue;

        QString ext(pFormat->extensions);
        ext.truncate(strcspn(pFormat->extensions, ","));
        format.extension = ext;
        format.shortName = pFormat->name;
        format.longName = QString("%1 (*.%2)").arg(pFormat->long_name).arg(ext);

        // FIXME: remove next line
        //format.longName += QString(" (%1)").arg(format.shortName);

        format.isRecomended = strcmp(pFormat->name, "mp4") == 0 || strcmp(pFormat->name, "avi") == 0;

        formats[pFormat->name] = format;
    }
}

void LibavInteraction::fillFormats(QComboBox * pFormats)
{
    // first insert recomended formats
    foreach(const Format & format, formats)
        if (format.isRecomended)
            pFormats->addItem(format.longName, format.shortName);

    // remember where to place separator between recomended and other formats
    int sep = pFormats->count();

    // insert remaining formats
    foreach(const Format & format, formats)
        if (!format.isRecomended)
            pFormats->addItem(format.longName, format.shortName);

    // insert separator if necessary
    if (sep != 0 && sep != pFormats->count())
        pFormats->insertSeparator(sep);
}

void LibavInteraction::fillCodecs(const QString & fmt, QComboBox * pVCodecs, QComboBox * pACodecs)
{
    Format & format = formats[fmt];

    // first insert recomended codecs
    foreach(Codec * codec, format.codecs)
    {
        if (codec->isRecomended)
        {
            if (codec->isAudio)
                pACodecs->addItem(codec->longName, codec->shortName);
            else
                pVCodecs->addItem(codec->longName, codec->shortName);
        }
    }

    // remember where to place separators between recomended and other codecs
    int vsep = pVCodecs->count();
    int asep = pACodecs->count();

    // insert remaining codecs
    foreach(Codec * codec, format.codecs)
    {
        if (!codec->isRecomended)
        {
            if (codec->isAudio)
                pACodecs->addItem(codec->longName, codec->shortName);
            else
                pVCodecs->addItem(codec->longName, codec->shortName);
        }
    }

    // insert separators if necessary
    if (vsep != 0 && vsep != pVCodecs->count())
        pVCodecs->insertSeparator(vsep);
    if (asep != 0 && asep != pACodecs->count())
        pACodecs->insertSeparator(asep);
}

QString LibavInteraction::getExtension(const QString & format)
{
    return formats[format].extension;
}

// get information abaout file (duration, resolution etc) in multiline string
QString LibavInteraction::getFileInfo(const QString & filepath)
{
    AVFormatContext* pContext = NULL;
    QByteArray utf8path = filepath.toUtf8();
    if (avformat_open_input(&pContext, utf8path.data(), NULL, NULL) < 0)
        return "";
#if LIBAVFORMAT_VERSION_MAJOR < 53
    if (av_find_stream_info(pContext) < 0)
#else
    if (avformat_find_stream_info(pContext, NULL) < 0)
#endif
        return "";

    int s = float(pContext->duration)/AV_TIME_BASE;
    QString desc = tr("Duration: %1m %2s").arg(s/60).arg(s%60) + "\n";
    for (int i = 0; i < (int)pContext->nb_streams; i++)
    {
        AVStream* pStream = pContext->streams[i];
        if (!pStream)
            continue;
        AVCodecContext* pCodec = pContext->streams[i]->codec;
        if (!pCodec)
            continue;

        if (pCodec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            desc += QString(tr("Video: %1x%2")).arg(pCodec->width).arg(pCodec->height) + ", ";
            if (pStream->avg_frame_rate.den)
            {
                float fps = float(pStream->avg_frame_rate.num)/pStream->avg_frame_rate.den;
                desc += QString(tr("%1 fps")).arg(fps, 0, 'f', 2) + ", ";
            }
        }
        else if (pCodec->codec_type == AVMEDIA_TYPE_AUDIO)
            desc += tr("Audio: ");
        else
            continue;
        AVCodec* pDecoder = avcodec_find_decoder(pCodec->codec_id);
        desc += pDecoder? pDecoder->name : tr("unknown");
        desc += "\n";
    }
    AVDictionaryEntry* pComment = av_dict_get(pContext->metadata, "comment", NULL, 0);
    if (pComment)
        desc += QString("\n") + pComment->value;
#if LIBAVFORMAT_VERSION_MAJOR < 53
    av_close_input_file(pContext);
#else
    avformat_close_input(&pContext);
#endif
    return desc;
}

#else
LibavInteraction::LibavInteraction() : QObject()
{

}

void LibavInteraction::fillFormats(QComboBox * pFormats)
{
    Q_UNUSED(pFormats);
}

void LibavInteraction::fillCodecs(const QString & format, QComboBox * pVCodecs, QComboBox * pACodecs)
{
    Q_UNUSED(format);
    Q_UNUSED(pVCodecs);
    Q_UNUSED(pACodecs);
}

QString LibavInteraction::getExtension(const QString & format)
{
    Q_UNUSED(format);

    return QString();
}

QString LibavInteraction::getFileInfo(const QString & filepath)
{
    Q_UNUSED(filepath);

    return QString();
}
#endif

LibavInteraction & LibavInteraction::instance()
{
    static LibavInteraction instance;
    return instance;
}
