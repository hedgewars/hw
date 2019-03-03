#include "preview_acceptor.h"

#include <QImage>
#include <QQmlEngine>

#include "preview_image_provider.h"

PreviewAcceptor::PreviewAcceptor(QQmlEngine *engine, QObject *parent)
    : QObject(parent), m_previewProvider(new PreviewImageProvider()) {
  engine->addImageProvider(QLatin1String("preview"), m_previewProvider);
}

void PreviewAcceptor::setImage(const QImage &preview) {
  m_previewProvider->setImage(preview);
}
