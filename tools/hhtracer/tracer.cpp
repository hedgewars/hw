#include "tracer.h"

#include <QRandomGenerator>
#include <QSvgGenerator>

Tracer::Tracer(QObject *parent)
    : QObject{parent},
      palette_{{Qt::black,
                Qt::white,
                {"#9f086e"},
                {"#f29ce7"},
                {"#54a2fa"},
                {"#2c78d2"}}} {}

QList<QColor> Tracer::palette() const { return palette_; }

void Tracer::setPalette(const QList<QColor> &newPalette) {
  if (palette_ == newPalette) return;
  palette_ = newPalette;
  emit paletteChanged();
}

double Tracer::bestSolution() const { return bestSolution_; }

void Tracer::start(const QString &fileName) {
  qDebug() << "Starting using" << fileName;

  bestSolution_ = 0;
  solutions_.clear();
  generation_.clear();
  referenceImage_ = QImage{};

  if (palette_.isEmpty()) {
    qDebug("Empty palette");
    return;
  }

  referenceImage_.load(QUrl(fileName).toLocalFile());

  if (referenceImage_.isNull()) {
    qDebug("Failed to load image");
    return;
  }

  for (int i = 0; i < 600; ++i) {
    generation_.append(Solution{{32, 32}, palette_});
  }
}

void Tracer::step() {
  const auto size = generation_.size();
  const auto keepSize = 10;
  const auto replaceSize = 50;
  const auto kept = generation_.mid(0, keepSize);
  generation_ = generation_.mid(0, size - replaceSize);

  for (int i = 0; i < replaceSize; ++i) {
    generation_.append(Solution{{32, 32}, palette_});
  }

  auto rg = QRandomGenerator::global();

  for (qsizetype i = 0; i < size; i += 4) {
    const auto first = rg->bounded(size);
    const auto second = rg->bounded(size);

    if (first != second) {
      generation_[first].crossover(generation_[second]);
    }
  }

  std::for_each(std::begin(generation_), std::end(generation_),
                [this](auto &s) { s.mutate(palette_); });

  std::for_each(std::begin(solutions_), std::end(solutions_),
                [this](const auto &fn) { QFile::remove(fn); });
  solutions_.clear();

  generation_.append(kept);

  for (auto &solution : generation_) {
    solution.render(newFileName());

    solution.calculateFitness(referenceImage_);

    solution.fitness += solution.cost() * 100;
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

Solution::Solution(QSizeF size, const QList<QColor> &palette) : size{size} {
  fitness = 0;
  primitives = {Primitive(size, palette), Primitive(size, palette)};
}

void Solution::calculateFitness(const QImage &target) {
  QImage candidate{fileName};

  if (candidate.isNull()) {
    fitness = 1e32;
    return;
  }

  // Both images assumed same size, same format
  double diffSum = 0;
  int width = target.width();
  int height = target.height();

  for (int y = 0; y < height; ++y) {
    auto candScan = reinterpret_cast<const QRgb *>(candidate.scanLine(y));
    auto targScan = reinterpret_cast<const QRgb *>(target.scanLine(y));
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
      diffSum +=
          qMax(qMax(qMax(dr * dr, dg * dg), db * db) * ta, da * da * 1.0);
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

void Solution::mutate(const QList<QColor> &palette) {
  if (primitives.isEmpty()) {
    return;
  }

  auto rg = QRandomGenerator::global();
  double mutationRate = 0.05;

  if (rg->bounded(1.0) > mutationRate) {
    return;
  }

  for (auto &prim : primitives) {
    // Pen width
    if (rg->bounded(1.0) < mutationRate) {
      prim.pen.setWidthF(prim.pen.widthF() * (rg->bounded(1.5) + 0.5) + 0.05);
    }

    // Origin
    if (rg->bounded(1.0) < mutationRate) {
      prim.origin += QPointF(rg->bounded(10.0) - 5.0, rg->bounded(10.0) - 5.0);
    }

    if (prim.type == Polygon) {
      // Points
      for (auto &pt : prim.points) {
        if (rg->bounded(1.0) < mutationRate) {
          prim.origin +=
              QPointF(rg->bounded(10.0) - 5.0, rg->bounded(10.0) - 5.0);
        }
      }
    } else {  // Circle/ellipse
      if (rg->bounded(1.0) < mutationRate) {
        prim.radius1 *= rg->bounded(0.4) + 0.8;
      }
      if (rg->bounded(1.0) < mutationRate) {
        prim.radius2 *= rg->bounded(0.4) + 0.8;
      }
      if (rg->bounded(1.0) < mutationRate) {
        prim.rotation = rg->bounded(90.0);
      }
    }
  }

  if (rg->bounded(1.0) < mutationRate) {
    auto i = rg->bounded(primitives.size());

    Primitive p{size, palette};
    primitives.insert(i, p);
  }

  if (rg->bounded(1.0) < mutationRate) {
    auto i = rg->bounded(primitives.size());

    primitives.remove(i);
  }
}

void Solution::crossover(Solution &other) {
  const auto n = qMin(primitives.size(), other.primitives.size());

  auto rg = QRandomGenerator::global();

  if (rg->bounded(1.0) < 0.02) {
    if (n <= 1) {
      return;
    }
    // swap tails
    const auto cp = rg->bounded(1, primitives.size());
    const auto ocp = rg->bounded(1, other.primitives.size());

    const auto tail = primitives.mid(cp);
    const auto otherTail = other.primitives.mid(ocp);

    primitives.remove(cp, primitives.size() - cp);
    other.primitives.remove(ocp, other.primitives.size() - ocp);

    primitives.append(otherTail);
    other.primitives.append(tail);
  } else {
    if (n < 1) {
      return;
    }
    // swap one element
    const auto cp = rg->bounded(primitives.size());
    const auto ocp = rg->bounded(other.primitives.size());

    qSwap(primitives[cp], other.primitives[ocp]);
  }
}

Primitive::Primitive(QSizeF size, const QList<QColor> &palette) {
  auto rg = QRandomGenerator::global();
  auto randomPoint = [&]() -> QPointF {
    return {rg->bounded(size.width()), rg->bounded(size.height())};
  };

  if (rg->bounded(2) == 0) {
    type = Polygon;

    points.append(randomPoint());
    points.append(randomPoint());
  } else {
    type = Circle;

    radius1 = rg->bounded(size.width() * 0.2) + 2;
    radius2 = rg->bounded(size.width() * 0.2) + 2;
    rotation = rg->bounded(90);
  }

  pen = QPen(palette[rg->bounded(palette.length())]);
  pen.setWidthF(rg->bounded(size.width() * 0.1));
  brush = QBrush(palette[rg->bounded(palette.length())]);

  origin = randomPoint();
}

double Primitive::cost() const { return 1.0 + 0.1 * points.length(); }
