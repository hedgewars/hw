import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Window {
  id: control

  width: 1024
  height: 768
  visible: true
  title: qsTr("Map Templates")

  property bool hasError: false

  Page {
    id: page
    anchors.fill: parent

    Rectangle {
      id: mapContainer

      property int spaceForCode: Math.max(200, parent.height / 2)
      property int mapWidth: 2048
      property int mapHeight: 1024
      property real aspectRatio: mapWidth / mapHeight
      property bool fitWidth: aspectRatio > (parent.width / (parent.height - spaceForCode))

      implicitWidth: fitWidth ? parent.width : (parent.height - spaceForCode) * aspectRatio
      implicitHeight: fitWidth ? parent.width / aspectRatio : (parent.height - spaceForCode)

      x: (parent.width - width) / 2

      border.width: 2
      border.color: hasError ? "red" : "black"
    }

    Shape {
      id: shape

      anchors.fill: mapContainer
    }

    Rectangle {
      anchors.fill: codeInput
      color: "gray"
    }

    TextEdit {
      id: codeInput

      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: parent.height - mapContainer.height

      text: "  -
    width: 3072
    height: 1424
    can_flip: false
    can_invert: false
    can_mirror: true
    is_negative: false
    put_girders: true
    max_hedgehogs: 18
    outline_points:
      -
        - {x: 748, y: 1424, w: 1, h: 1}
        - {x: 636, y: 1252, w: 208, h: 72}
        - {x: 898, y: 1110, w: 308, h: 60}
        - {x: 1128, y: 1252, w: 434, h: 40}
        - {x: 1574, y: 1112, w: 332, h: 40}
        - {x: 1802, y: 1238, w: 226, h: 36}
        - {x: 1930, y: 1424, w: 1, h: 1}
      -
        - {x: 2060, y: 898, w: 111, h: 111}
        - {x: 1670, y: 876, w: 34, h: 102}
        - {x: 1082, y: 814, w: 284, h: 132}
        - {x: 630, y: 728, w: 126, h: 168}
        - {x: 810, y: 574, w: 114, h: 100}
        - {x: 1190, y: 572, w: 352, h: 120}
        - {x: 1674, y: 528, w: 60, h: 240}
        - {x: 1834, y: 622, w: 254, h: 116}
    fill_points:
      - {x: 1423, y: 0}
"

      onTextChanged: {
        const template = parseInput()

        if (template) {
          mapContainer.mapWidth = Number(template.width)
          mapContainer.mapHeight = Number(template.height)

          shape.data = renderTemplate(template)
        }
      }
    }
  }

  function parseInput() {
    let code = codeInput.text.split('\n')

    if(code[0] !== "  -") {
      hasError = true
      return
    }

    code = code.slice(1)
    code.push("")

    let parsed = ({})
    let polygonAccumulator = []
    let pointAccumulator = []
    let key = ""
    code.forEach(line => {
                   let newKey
                   if (line === "    outline_points:") {
                     newKey = "outline_points"
                   }

                   if (line === "    holes:") {
                     newKey = "holes"
                   }

                   if (line === "    fill_points:") {
                     newKey = "fill_points"
                   }

                   if (line === "") {
                     newKey = "_"
                   }

                   if (key === "fill_points" && line.startsWith("      - {")) {
                     // ignore
                     return
                   }

                   if (newKey) {
                     if (key.length > 0) {
                       polygonAccumulator.push(pointAccumulator)
                       parsed[key] = polygonAccumulator
                     }

                     key = newKey
                     polygonAccumulator = []
                     pointAccumulator = []

                     return
                   }

                   if (line === "      -") {
                    if (pointAccumulator.length > 0) {
                       polygonAccumulator.push(pointAccumulator)
                       pointAccumulator = []
                     }

                     return
                   }

                   const matchValue = line.match(/^\s{4}(\w+):\s(.+)$/);

                   if (matchValue) {
                     parsed[matchValue[1]] = matchValue[2]
                     return
                   }

                   const matchPoint = line.match(/^\s{8}-\s\{([^}]+)\}$/);

                   if (matchPoint) {
                    const point = matchPoint[1].split(", ").reduce((obj, pair) => {
                                                              const [key, value] = pair.split(": ");
                                                              obj[key] = isNaN(value) ? value : parseInt(value);
                                                              return obj;
                                                            }, {})
                    pointAccumulator.push(point)
                    return
                   }

                   console.log("Unrecognized: " + JSON.stringify(line))
                   hasError = true
                   throw ""
                 })

    hasError = false

    return parsed
  }

  Component {
    id: shapePathComponent

    ShapePath {
      fillColor: "transparent"
      scale: Qt.size(mapContainer.width / mapContainer.mapWidth, mapContainer.height / mapContainer.mapHeight)
      strokeWidth: 3
    }
  }

  Component {
    id: pathLineComponent
    PathLine {
    }
  }

  function polygons2shapes(polygons, lineColor, rectColor) {
    if (!Array.isArray(polygons)) {
      return []
    }

    let rectangles = []

    polygons.forEach(polygon => polygon.forEach(r => {
                                                   let shapePath = shapePathComponent.createObject(shape)
                                                   shapePath.strokeWidth = 1
                                                   shapePath.strokeColor = rectColor

                                                   shapePath.startX = r.x
                                                   shapePath.startY = r.y
                                                   shapePath.pathElements = [
                                                      pathLineComponent.createObject(shapePath, {x: r.x, y: r.y + r.h}),
                                                      pathLineComponent.createObject(shapePath, {x: r.x + r.w, y: r.y + r.h}),
                                                      pathLineComponent.createObject(shapePath, {x: r.x + r.w, y: r.y}),
                                                      pathLineComponent.createObject(shapePath, {x: r.x, y: r.y})
                                                   ]

                                                   rectangles.push(shapePath)
                                                 }))
    let polygonShapes = polygons.map(polygon => {
                                             let points = polygon.map(r => ({x: r.x + r.w / 2, y: r.y + r.h / 2}))
                                             let shapePath = shapePathComponent.createObject(shape)
                                             let start = points[points.length - 1]

                                             shapePath.strokeColor = lineColor
                                             shapePath.startX = start.x
                                             shapePath.startY = start.y
                                             shapePath.pathElements = points.map(p => pathLineComponent.createObject(shapePath, p))

                                             return shapePath
                                             })

    return rectangles.concat(polygonShapes)
  }

  function renderTemplate(template) {
    return polygons2shapes(template.outline_points, "red", "black").concat(polygons2shapes(template.holes, "gray", "gray"))
  }
}
