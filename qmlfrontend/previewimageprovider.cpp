#include "previewimageprovider.h"

PreviewImageProvider::PreviewImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap PreviewImageProvider::requestPixmap(const QString &id, QSize *size,
                                            const QSize &requestedSize) {
  Q_UNUSED(id);
  Q_UNUSED(requestedSize);

  if (size) *size = m_px.size();

  return m_px;
}

void PreviewImageProvider::setPixmap(const QByteArray &px) {
  QVector<QRgb> colorTable;
  colorTable.resize(256);
  for (int i = 0; i < 256; ++i) colorTable[i] = qRgba(255, 255, 0, i);

  const quint8 *buf = (const quint8 *)px.constData();
  QImage im(buf, 256, 128, QImage::Format_Indexed8);
  im.setColorTable(colorTable);

  m_px = QPixmap::fromImage(im, Qt::ColorOnly);
  // QPixmap pxres(px.size());
  // QPainter p(&pxres);

  // p.fillRect(pxres.rect(), linearGrad);
  // p.drawPixmap(0, 0, px);
}
