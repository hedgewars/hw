#pragma once

#include <QObject>
#include <QPainter>
#include <QQmlEngine>
#include <QTemporaryDir>

enum PrimitiveType { Polygon, Circle };

struct Primitive {
  PrimitiveType type;
  QPen pen;
  QBrush brush;
  QPointF origin;
  QList<QPointF> points;                    // polygon
  double radius1{}, radius2{}, rotation{};  // ellipse

  explicit Primitive(QSizeF size, const QList<QColor>& palette);
  double cost() const;
};

struct Solution {
  QList<Primitive> primitives;
  double fitness;
  QSizeF size;
  QString fileName;

  explicit Solution(QSizeF size, const QList<QColor>& palette);
  void calculateFitness(const QImage& target);
  void render(const QString& fileName);
  double cost() const;
  void mutate(const QList<QColor>& palette);
  void crossover(Solution &other);
};

class Tracer : public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QList<QColor> palette READ palette WRITE setPalette NOTIFY
                 paletteChanged FINAL)
  Q_PROPERTY(
      double bestSolution READ bestSolution NOTIFY bestSolutionChanged FINAL)
  Q_PROPERTY(QStringList solutions READ solutions NOTIFY solutionsChanged FINAL)

 public:
  explicit Tracer(QObject *parent = nullptr);

  QList<QColor> palette() const;
  void setPalette(const QList<QColor>& newPalette);

  double bestSolution() const;

  Q_INVOKABLE void start(const QString& fileName);
  Q_INVOKABLE void step();

  QStringList solutions() const;

 Q_SIGNALS:
  void paletteChanged();
  void bestSolutionChanged();
  void solutionsChanged();

 private:
  QList<QColor> palette_;
  double bestSolution_;
  QStringList solutions_;
  QList<Solution> generation_;
  QTemporaryDir tempDir_;
  QImage referenceImage_;

  QString newFileName();
};
