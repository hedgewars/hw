#pragma once

#include <QJsonArray>
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

  explicit Primitive(QSizeF size, const QJsonObject& atom);
  double cost() const;
};

struct Solution {
  QList<Primitive> primitives;
  double fitness{1e64};
  QSizeF size;
  QString fileName;
  quint32 gen;

  explicit Solution(QSizeF size, const QJsonArray& atoms);
  void calculateFitness(const QImage& target);
  void render(const QString& fileName);
  double cost() const;
  void mutate();
  void crossover(Solution &other);
};

class Tracer : public QObject {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(
      QJsonArray atoms READ atoms WRITE setAtoms NOTIFY atomsChanged FINAL)
  Q_PROPERTY(
      double bestSolution READ bestSolution NOTIFY bestSolutionChanged FINAL)
  Q_PROPERTY(QStringList solutions READ solutions NOTIFY solutionsChanged FINAL)

 public:
  explicit Tracer(QObject *parent = nullptr);

  double bestSolution() const;

  Q_INVOKABLE void start(const QString& fileName);
  Q_INVOKABLE void step();

  QStringList solutions() const;

  QJsonArray atoms() const;
  void setAtoms(const QJsonArray& newAtoms);

 Q_SIGNALS:
  void bestSolutionChanged();
  void solutionsChanged();
  void atomsChanged();

 private:
  double bestSolution_;
  QStringList solutions_;
  QList<Solution> generation_;
  QTemporaryDir tempDir_;
  QImage referenceImage_;
  QJsonArray atoms_;

  QString newFileName();
};
