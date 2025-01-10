#include "tracer.h"

#include <QRandomGenerator>
#include <QSvgGenerator>

Tracer::Tracer(QObject* parent)
    : QObject{parent},
      palette_{{Qt::black,
                Qt::white,
                {"#f29ce7"},
                {"#9f086e"},
                {"#54a2fa"},
                {"#2c78d2"}}} {}

QList<QColor> Tracer::palette() const { return palette_; }

void Tracer::setPalette(const QList<QColor>& newPalette) {
  if (palette_ == newPalette) return;
  palette_ = newPalette;
  emit paletteChanged();
}

double Tracer::bestSolution() const { return bestSolution_; }

void Tracer::start(const QString& fileName) {
  qDebug() << "Starting using" << fileName;

  bestSolution_ = 0;
  solutions_.clear();
  generation_.clear();
  image_ = QImage{};

  if (palette_.isEmpty()) {
    qDebug("Empty palette");
    return;
  }

  image_.load(QUrl(fileName).toLocalFile());

  if (image_.isNull()) {
    qDebug("Failed to load image");
    return;
  }

  for (int i = 0; i < 100; ++i) {
    generation_.append(Solution{{32, 32}, palette_});
  }
}

void Tracer::step() {
  solutions_.clear();

  for (auto& solution : generation_) {
    const auto fileName = newFileName();
    solutions_.append(fileName);

    solution.render(fileName);
  }

  qDebug() << solutions_;

  emit solutionsChanged();
}

QStringList Tracer::solutions() const { return solutions_; }

QString Tracer::newFileName() {
  static qlonglong counter{0};
  counter += 1;
  return tempDir_.filePath(
      QStringLiteral("hedgehog_%1.svg").arg(counter, 3, 32, QChar(u'_')));
}

Solution::Solution(QSizeF size, const QList<QColor>& palette) : size{size} {
  fitness = 0;
  primitives = {Primitive(size, palette)};
}

void Solution::render(const QString& fileName) const {
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

  for (const auto& primitive : primitives) {
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

Primitive::Primitive(QSizeF size, const QList<QColor>& palette) {
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

    radius1 = rg->bounded(size.width());
    radius2 = rg->bounded(size.width());
    rotation = rg->bounded(90);
  }

  pen = QPen(palette[rg->bounded(palette.length())]);
  pen.setWidthF(rg->bounded(size.width() * 0.1));
  brush = QBrush(palette[rg->bounded(palette.length())]);

  origin = randomPoint();
}

double Primitive::cost() const { return 1.0 + 0.1 * points.length(); }
