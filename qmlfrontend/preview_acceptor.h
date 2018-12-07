#ifndef PREVIEW_ACCEPTOR_H
#define PREVIEW_ACCEPTOR_H

#include <QObject>

class QQmlEngine;
class PreviewImageProvider;

class PreviewAcceptor : public QObject {
  Q_OBJECT
 public:
  explicit PreviewAcceptor(QQmlEngine *engine, QObject *parent = nullptr);

 public slots:
  void setImage(const QImage &preview);

 private:
  PreviewImageProvider *m_previewProvider;
};

#endif  // PREVIEW_ACCEPTOR_H
