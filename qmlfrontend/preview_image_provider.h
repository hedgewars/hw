#ifndef PREVIEWIMAGEPROVIDER_H
#define PREVIEWIMAGEPROVIDER_H

#include <QPixmap>
#include <QQuickImageProvider>
#include <QSize>

class PreviewImageProvider : public QQuickImageProvider {
 public:
  PreviewImageProvider();

  QPixmap requestPixmap(const QString &id, QSize *size,
                        const QSize &requestedSize);

  void setImage(const QImage &preview);

 private:
  QPixmap m_px;
};

#endif  // PREVIEWIMAGEPROVIDER_H
