#include "tracer.h"

#include <QJsonObject>
#include <QRandomGenerator>
#include <QSvgGenerator>

Tracer::Tracer(QObject *parent) : QObject{parent} {}

double Tracer::bestSolution() const { return bestSolution_; }

void Tracer::start(const QString &fileName) {
  qDebug() << "Starting using" << fileName;

  bestSolution_ = 0;
  solutions_.clear();
  generation_.clear();
  referenceImage_ = QImage{};

  referenceImage_.load(QUrl(fileName).toLocalFile());

  if (referenceImage_.isNull()) {
    qDebug("Failed to load image");
    return;
  }

  referenceImage_ = referenceImage_.convertedTo(QImage::Format_RGBA8888);

  for (int i = 0; i < 600; ++i) {
    generation_.append(Solution{referenceImage_.size(), atoms_});
  }
}

void Tracer::step() {
  const auto size = generation_.size();
  const auto keepSize = 1;
  const auto replaceSize = 10;
  const auto kept = generation_.mid(0, keepSize);
  generation_ = generation_.mid(0, size - replaceSize);

  std::for_each(std::begin(generation_), std::end(generation_),
                [](auto &s) { s.mutate(); });

  for (int i = 0; i < replaceSize; ++i) {
    generation_.append(Solution{referenceImage_.size(), atoms_});
  }

  auto rg = QRandomGenerator::global();

  for (qsizetype i = 0; i < size; i += 6) {
    const auto first = rg->bounded(size);
    const auto second = rg->bounded(size);

    if (first != second) {
      generation_[first].crossover(generation_[second]);
    }
  }

  std::for_each(std::begin(solutions_), std::end(solutions_),
                [](const auto &fn) { QFile::remove(fn); });
  solutions_.clear();

  generation_.append(kept);

  for (auto &solution : generation_) {
    solution.render(newFileName());

    solution.calculateFitness(referenceImage_);

    solution.fitness += solution.cost() * 1e4;
  }

  std::sort(std::begin(generation_), std::end(generation_),
            [](const auto &a, const auto &b) { return a.fitness < b.fitness; });

  std::for_each(std::begin(generation_) + size, std::end(generation_),
                [](const auto &s) { QFile::remove(s.fileName); });
  generation_.remove(size, kept.size());

  bestSolution_ = generation_[0].fitness;

  std::transform(std::begin(generation_), std::end(generation_),
                 std::back_inserter(solutions_),
                 [](const auto &a) { return a.fileName; });

  emit bestSolutionChanged();
  emit solutionsChanged();
}

QStringList Tracer::solutions() const { return solutions_; }

QString Tracer::newFileName() {
  static qlonglong counter{0};
  counter += 1;
  return tempDir_.filePath(
      QStringLiteral("hedgehog_%1.svg").arg(counter, 3, 32, QChar(u'_')));
}

Solution::Solution(QSizeF size, const QJsonArray &atoms) : size{size} {
  fitness = 0;

  std::transform(std::begin(atoms), std::end(atoms),
                 std::back_inserter(primitives),
                 [&](const auto &a) { return Primitive{size, a.toObject()}; });
}

void Solution::calculateFitness(const QImage &target) {
  QImage candidate{fileName};

  if (candidate.isNull()) {
    fitness = 1e32;
    return;
  }

  candidate = candidate.convertedTo(QImage::Format_RGBA8888);

  // Both images assumed same size, same format
  double diffSum = 0;
  int width = target.width();
  int height = target.height();

  for (int y = 0; y < height; ++y) {
    const auto candScan = reinterpret_cast<const QRgb *>(candidate.scanLine(y));
    const auto targScan = reinterpret_cast<const QRgb *>(target.scanLine(y));
    for (int x = 0; x < width; ++x) {
      // Compare RGBA channels
      const QRgb cPix = candScan[x];
      const QRgb tPix = targScan[x];
      // const auto ca = qAlpha(cPix) / 255.0;
      const auto ta = qAlpha(tPix) / 255.0;
      const auto dr = qRed(cPix) - qRed(tPix);
      const auto dg = qGreen(cPix) - qGreen(tPix);
      const auto db = qBlue(cPix) - qBlue(tPix);
      const auto da = qAlpha(cPix) - qAlpha(tPix);
      diffSum += (dr * dr + dg * dg + db * db) * ta + da * da;
    }
  }

  fitness = diffSum;
}

void Solution::render(const QString &fileName) {
  this->fileName = fileName;

  const auto imageSize = size.toSize();

  QSvgGenerator generator;
  generator.setFileName(fileName);
  generator.setSize(imageSize);
  generator.setViewBox(QRect(0, 0, imageSize.width(), imageSize.height()));
  generator.setTitle("Hedgehog");
  generator.setDescription("Approximation of a target image using primitives");

  QPainter painter;
  painter.begin(&generator);
  painter.setRenderHint(QPainter::Antialiasing, true);

  for (const auto &primitive : primitives) {
    painter.setPen(primitive.pen);
    painter.setBrush(primitive.brush);
    painter.resetTransform();
    painter.translate(primitive.origin);
    painter.rotate(primitive.rotation);

    switch (primitive.type) {
      case Polygon: {
        QPolygonF polygon;
        polygon.append({0, 0});
        polygon.append(primitive.points);

        painter.drawPolygon(polygon);
        break;
      }
      case Circle:
        painter.drawEllipse({0, 0}, primitive.radius1, primitive.radius2);
        break;
    }
  }

  painter.end();
}

double Solution::cost() const {
  return std::accumulate(primitives.constBegin(), primitives.constEnd(), 0,
                         [](auto a, auto p) { return a + p.cost(); });
}

void Solution::mutate() {
  if (primitives.isEmpty()) {
    return;
  }

  auto rg = QRandomGenerator::global();
  double mutationRate = 0.1;

  for (auto &prim : primitives) {
    // Pen width
    if (rg->bounded(1.0) < mutationRate) {
      prim.pen.setWidthF(prim.pen.widthF() * (rg->bounded(0.5) + 0.8) + 0.01);
    }

    // Origin
    if (rg->bounded(1.0) < mutationRate) {
      prim.origin += QPointF(rg->bounded(4.0) - 2.0, rg->bounded(4.0) - 2.0);
    }

    if (prim.type == Polygon) {
      // Points
      for (auto &pt : prim.points) {
        if (rg->bounded(1.0) < mutationRate) {
          pt += QPointF(rg->bounded(2.0) - 1.0, rg->bounded(2.0) - 1.0);
        }
      }
    } else {  // Circle/ellipse
      if (rg->bounded(1.0) < mutationRate) {
        prim.radius1 *= rg->bounded(0.5) + 0.8;
      }
      if (rg->bounded(1.0) < mutationRate) {
        prim.radius2 *= rg->bounded(0.5) + 0.8;
      }
      if (rg->bounded(1.0) < mutationRate) {
        prim.rotation = rg->bounded(90.0);
      }
    }
  }

  if (rg->bounded(1.0) < mutationRate) {
    const auto i = rg->bounded(primitives.size());

    primitives.insert(i, primitives[i]);
  }

  if (rg->bounded(1.0) < mutationRate) {
    const auto a = rg->bounded(primitives.size());
    const auto b = rg->bounded(primitives.size());

    qSwap(primitives[a], primitives[b]);
  }

  if (rg->bounded(1.0) < mutationRate) {
    const auto i = rg->bounded(primitives.size());

    primitives.remove(i);
  }
}

void Solution::crossover(Solution &other) {
  auto rg = QRandomGenerator::global();

  const auto n = qMin(primitives.size(), other.primitives.size());

  if (n <= 1) {
    return;
  }

  // swap one element
  const auto cp = rg->bounded(n);
  const auto ocp = rg->bounded(n);

  qSwap(primitives[cp], other.primitives[ocp]);
}

Primitive::Primitive(QSizeF size, const QJsonObject &atom) {
  auto rg = QRandomGenerator::global();
  auto randomPoint = [&]() -> QPointF {
    return {rg->bounded(size.width()), rg->bounded(size.height())};
  };

  if (atom["type"] == "polygon") {
    type = Polygon;

    for (int i = 1; i < atom["length"].toInt(3); ++i) {
      points.append(randomPoint());
    }
  } else if (atom["type"] == "circle") {
    type = Circle;

    radius1 = rg->bounded(size.width() * 0.2) + 2;
    radius2 = rg->bounded(size.width() * 0.2) + 2;
    rotation = rg->bounded(90);
  }

  const auto pens = atom["pens"].toVariant().toStringList();
  pen = QPen(pens[rg->bounded(pens.length())]);
  pen.setWidthF(rg->bounded(size.width() * 0.05));
  pen.setJoinStyle(Qt::RoundJoin);

  const auto brushes = atom["brushes"].toVariant().toStringList();
  brush = QBrush(QColor(brushes[rg->bounded(brushes.length())]));

  origin = randomPoint();
}

double Primitive::cost() const { return 1.0 + 0.1 * points.length(); }

QJsonArray Tracer::atoms() const { return atoms_; }

void Tracer::setAtoms(const QJsonArray &newAtoms) {
  if (atoms_ == newAtoms) return;
  atoms_ = newAtoms;
  emit atomsChanged();
}
