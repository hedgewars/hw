#ifndef HWENGINE_H
#define HWENGINE_H

#include <QObject>

class HWEngine : public QObject
{
    Q_OBJECT
public:
    explicit HWEngine(QObject *parent = 0);
    ~HWEngine();

    static void exposeToQML();
    Q_INVOKABLE void run();
    
signals:
    
public slots:
    
};

#endif // HWENGINE_H

