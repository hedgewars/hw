#ifndef GAMEVIEW_H
#define GAMEVIEW_H

#include <QQuickItem>

#include <QtGui/QOpenGLFunctions>
#include <QtGui/QOpenGLShaderProgram>

class GameViewRenderer : public QObject, protected QOpenGLFunctions {
    Q_OBJECT
public:
    GameViewRenderer()
        : m_delta(0)
    {
    }
    ~GameViewRenderer();

    void tick(quint32 delta) { m_delta = delta; }
    void setViewportSize(const QSize& size);

public slots:
    void paint();

private:
    quint32 m_delta;
};

class GameView : public QQuickItem {
    Q_OBJECT

public:
    GameView();

    Q_INVOKABLE void tick(quint32 delta);

signals:
    void tChanged();

public slots:
    void sync();
    void cleanup();

private slots:
    void handleWindowChanged(QQuickWindow* win);

private:
    quint32 m_delta;
    GameViewRenderer* m_renderer;
    bool m_windowChanged;
    qint32 m_centerX;
    qint32 m_centerY;
};

#endif // GAMEVIEW_H
