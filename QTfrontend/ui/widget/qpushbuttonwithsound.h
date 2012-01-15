#ifndef QPUSHBUTTONWITHSOUND_H
#define QPUSHBUTTONWITHSOUND_H

#include <QPushButton>

class QPushButtonWithSound : public QPushButton
{
    Q_OBJECT
public:
    explicit QPushButtonWithSound(QWidget *parent = 0);

signals:
    
public slots:
private slots:
    void buttonClicked();
    
};

#endif // QPUSHBUTTONWITHSOUND_H
