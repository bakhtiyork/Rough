//
//  Renderer.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//


public class Renderer {
    
    init() {}
    
    func line(from: CGPoint, to: CGPoint, options: Options) -> Shape {
        let ops = pathOfDoubleLine(from: from, to: to, options: options)
        return Shape.path(path: Shape.toBezierPath(ops: ops, closed: false), options: options)
    }
    
    func linearPath(points: [CGPoint], close: Bool, options: Options) -> Shape {
        let len = points.count
        if len > 2 {
            var ops = [DrawOp]()
            for i in 0...len-2 {
                ops.append(contentsOf: pathOfDoubleLine(from: points[i], to: points[i+1], options: options))
            }
            if close {
                ops.append(contentsOf: pathOfDoubleLine(from: points.last!, to: points.first!, options: options))
            }
            let path = Shape.toBezierPath(ops: ops, closed: true)
            return Shape.path(path: path, options: options)
        } else if len == 2 {
            let path = Shape.toBezierPath(ops: pathOfDoubleLine(from: points.last!, to: points.first!, options: options), closed: false)
            return Shape.path(path: path, options: options)
        }
        return Shape.none
    }
    
    func polygon(points: [CGPoint], options: Options) -> Shape {
        return linearPath(points: points, close: true, options: options)
    }
    
    func curve(points: [CGPoint], options: Options) -> Shape {
        var ops1 = pathOfCurve(points: points, offset: 1 + options.roughness * 0.2, options: options)
        let ops2 = pathOfCurve(points: points, offset: 1.5 * (1 + options.roughness * 0.22), options: options)
        ops1.append(contentsOf: ops2)
        let path = Shape.toBezierPath(ops: ops1, closed: false)
        return Shape.path(path: path, options: options)
    }
    
    func ellipse(point: CGPoint, width: Float, height: Float, options: Options) -> Shape {
        let increment = (Float.pi * 2) / Float(options.curveStepCount)
        var rx = abs(width / 2.0)
        var ry = abs(height / 2.0)
        rx += getOffset(offset: rx * 0.05, options: options)
        ry += getOffset(offset: ry * 0.05, options: options)
        var ops1 = pathOfEllipse(increment: increment, center: point, rx: rx, ry: ry, offset: 1, overlap: increment * getOffset(min: 0.1, max: getOffset(min: 0.4, max: 1.0, options: options), options: options), options: options)
        let ops2 = pathOfEllipse(increment: increment, center: point, rx: rx, ry: ry, offset: 1.5, overlap: 0, options: options)
        ops1.append(contentsOf: ops2)
        let path = Shape.toBezierPath(ops: ops1, closed: true)
        return Shape.path(path: path, options: options)
    }
    
    func arc(center: CGPoint, width: Float, height: Float, start: Float, stop: Float, closed: Bool, roughClosure: Bool, options: Options) -> Shape {
        var ops = [DrawOp]()
        let cx = center.x.float
        let cy = center.y.float
        var rx = abs(width / 2)
        var ry = abs(height / 2)
        rx += getOffset(offset:rx * 0.01, options: options)
        ry += getOffset(offset:rx * 0.01, options: options)
        var strt = start
        var stp = stop
        while strt < 0 {
            strt += Float.pi * 2.0
            stp += Float.pi * 2.0
        }
        if (stp - strt) > (Float.pi * 2.0) {
            strt = 0
            stp = Float.pi * 2.0
        }
        let ellipseInc = (Float.pi * 2.0) / Float(options.curveStepCount)
        let arcInc = min(ellipseInc / 2.0, (stp - strt) / 2.0)
        let o1 = pathOfArc(increment: arcInc, cx: cx, cy: cy, rx: rx, ry: ry, strt: strt, stp: stp, offset: 1, options: options)
        let o2 = pathOfArc(increment: arcInc, cx: cx, cy: cy, rx: rx, ry: ry, strt: strt, stp: stp, offset: 1.5, options: options)
        ops.append(contentsOf: o1)
        ops.append(contentsOf: o2)
        if closed {
            if roughClosure {
                ops.append(contentsOf: pathOfDoubleLine(from: center, to: CGPoint(x: cx + rx * cos(strt), y: cy + ry * sin(strt)), options: options))
                ops.append(contentsOf: pathOfDoubleLine(from: center, to: CGPoint(x: cx + rx * cos(stp), y: cy + ry * sin(stp)), options: options))
            } else {
                ops.append(.line(to: center))
                ops.append(.line(to: CGPoint(x: cx + rx * cos(strt), y: cy + ry * sin(strt))))
            }
        }
        let path = Shape.toBezierPath(ops: ops, closed: closed)
        return .path(path: path, options: options)
    }
    
    func solidFillShape(points: [CGPoint], options: Options) -> Shape {
        var ops = [DrawOp]()
        if !points.isEmpty {
            var xs = [Float]()
            var ys = [Float]()
            for point in points {
                xs.append(point.x.float)
                ys.append(point.y.float)
            }
            let offset = options.maxRandomnessOffset
            let len = points.count
            if len > 2 {
                ops.append(.move(to: CGPoint(
                    x: xs[0] + getOffset(offset: offset, options: options),
                    y: ys[0] + getOffset(offset: offset, options: options)
                )))
                for i in 1...len-1 {
                    ops.append(.line(to: CGPoint(
                        x: xs[i] + getOffset(offset: offset, options: options),
                        y: ys[i] + getOffset(offset: offset, options: options)
                    )))
                }
            }
        }
        let path = Shape.toBezierPath(ops: ops, closed: true)
        return .fill(path: path, options: options)
    }
    
    func hachureFillShape(xs: [Float], ys: [Float], options: Options) -> Shape {
        var ops = [DrawOp]()
        if  let left = xs.min(),
            let right = xs.max(),
            let top = ys.min(),
            let bottom = ys.max()
        {
            let gap = max(options.hachureGap >= 0 ? options.hachureGap : options.strokeWidth * 4.0, 0.1)
            
            let hachureAngle = options.hachureAngle.degreesToRadians
            
            let cosAngle = cos(hachureAngle)
            let sinAngle = sin(hachureAngle)
            let tanAngle = tan(hachureAngle)
            let iterator = HachureIterator(top: top - 1, bottom: bottom + 1, left: left - 1, right: right + 1, gap: gap, sinAngle: sinAngle, cosAngle: cosAngle, tanAngle: tanAngle)
            
            while let rectCoords = iterator.next() {
                let lines = getIntersectingLines(lineCoords: rectCoords, xs: xs, ys: ys)
                if lines.count < 2 {
                    continue
                }
                
                for i in 0...lines.count-2 {
                    let p1 = lines[i]
                    let p2 = lines[i+1]
                    ops.append(contentsOf: pathOfDoubleLine(from: p1, to: p2, options: options))
                }
            }
        }
        let path = Shape.toBezierPath(ops: ops, closed: false)
        return .hachure(path: path, options: options)
    }
    
    func hachureFillShape(points: [CGPoint], options: Options) -> Shape {
        var xs = [Float]()
        var ys = [Float]()
        for point in points {
            xs.append(point.x.float)
            ys.append(point.y.float)
        }
        return hachureFillShape(xs: xs, ys: ys, options: options)
    }
    
    func hachureFillEllipse(center: CGPoint, width: Float, height: Float, options: Options) -> Shape {
        var ops = [DrawOp]()
        let cx = center.x.float
        let cy = center.y.float
        var rx = abs(width / 2.0)
        var ry = abs(height / 2.0)
        rx += getOffset(offset: rx * 0.05, options: options)
        ry += getOffset(offset: ry * 0.05, options: options)
        var gap = options.hachureGap
        if gap < 0 {
            gap = options.strokeWidth * 4.0
        }
        var fweight = options.fillWeight
        if fweight < 0 {
            fweight = options.strokeWidth / 2.0
        }
        let angle = options.hachureAngle.degreesToRadians
        let tanAngle = tan(angle)
        let aspectRatio = ry / rx
        let hyp = sqrt(aspectRatio * tanAngle * aspectRatio * tanAngle + 1)
        let sinAnglePrime = aspectRatio * tanAngle / hyp
        let cosAnglePrime = 1 / hyp
        let gapPrime = gap / ((rx * ry / sqrt((ry * cosAnglePrime) * (ry * cosAnglePrime) + (rx * sinAnglePrime) * (rx * sinAnglePrime))) / rx)
        var halfLen = sqrt((rx * rx) - (cx - rx + gapPrime) * (cx - rx + gapPrime))
        var xPos = cx - rx + gapPrime
        while xPos < cx + rx {
            halfLen = sqrt((rx * rx) - (cx - xPos) * (cx - xPos))
            let p1 = affine(x: xPos, y: cy - halfLen, cx: cx, cy: cy, sinAnglePrime: sinAnglePrime, cosAnglePrime: cosAnglePrime, R: aspectRatio)
            let p2 = affine(x: xPos, y: cy + halfLen, cx: cx, cy: cy, sinAnglePrime: sinAnglePrime, cosAnglePrime: cosAnglePrime, R: aspectRatio)
            ops.append(contentsOf: pathOfDoubleLine(from: CGPoint(pair: p1), to: CGPoint(pair: p2), options: options))
            xPos += gapPrime
        }
        let path = Shape.toBezierPath(ops: ops, closed: false)
        return .hachure(path: path, options: options)
    }
    
    func hachureFillArc(center: CGPoint, width: Float, height: Float, start: Float, stop: Float, options: Options) -> Shape {
        var points = [CGPoint]()
        
        let cx = center.x.float
        let cy = center.y.float
        var rx = abs(width / 2)
        var ry = abs(height / 2)
        rx += getOffset(offset:rx * 0.01, options: options)
        ry += getOffset(offset:rx * 0.01, options: options)
        var strt = start
        var stp = stop
        while strt < 0 {
            strt += Float.pi * 2.0
            stp += Float.pi * 2.0
        }
        if (stp - strt) > (Float.pi * 2.0) {
            strt = 0
            stp = Float.pi * 2.0
        }
        let increment = (Float.pi * 2.0) / Float(options.curveStepCount)
        var angle = strt
        while angle < stp {
            points.append(CGPoint(
                x: cx + rx * cos(angle),
                y: cy + ry * sin(angle)
            ))
            angle += increment
        }
        points.append(CGPoint(
            x: cx + rx * cos(stp),
            y: cy + ry * sin(stp)
        ))
        points.append(center)
        
        return hachureFillShape(points: points, options: options)
    }
    
    func svgPath(svg: String, options: Options) -> Shape {
        return .none
    }
    
    func pathOfLine(from: CGPoint, to: CGPoint, options: Options, move: Bool, overlay: Bool) -> [DrawOp] {
        var ops = [DrawOp]()
        
        let x1 = from.x.float
        let y1 = from.y.float
        let x2 = to.x.float
        let y2 = to.y.float
        
        let lengthSq = pow((x1 - x2), 2) + pow((y1 - y2), 2)
        var offset = options.maxRandomnessOffset
        if (offset * offset * 100) > lengthSq {
            offset = sqrt(lengthSq) / 10
        }
        let halfOffset = offset / 2.0
        let divergePoint = 0.2 + Float.random * 0.2
        var midDispX = options.bowing * options.maxRandomnessOffset * (y2 - y1) / 200.0
        var midDispY = options.bowing * options.maxRandomnessOffset * (x1 - x2) / 200.0
        midDispX = getOffset(offset: midDispX, options: options)
        midDispY = getOffset(offset: midDispY, options: options)
        
        if move {
            if overlay {
                let point = CGPoint(
                    x: x1 + getOffset(offset: halfOffset, options: options),
                    y: y1 + getOffset(offset: halfOffset, options: options)
                )
                ops.append(DrawOp.move(to: point))
            } else {
                let point = CGPoint(
                    x: x1 + getOffset(offset: offset, options: options),
                    y: y1 + getOffset(offset: offset, options: options)
                )
                ops.append(DrawOp.move(to: point))
            }
        }
        if overlay {
            ops.append(DrawOp.bezierCurve(
                to: CGPoint(
                    x: x2 + getOffset(offset: halfOffset, options: options),
                    y: y2 + getOffset(offset: halfOffset, options: options)
                ),
                controlPoint1: CGPoint(
                    x: midDispX + x1 + (x2 - x1) * divergePoint + getOffset(offset: halfOffset, options: options),
                    y: midDispY + y1 + (y2 - y1) * divergePoint + getOffset(offset: halfOffset, options: options)
                ),
                controlPoint2: CGPoint(
                    x: midDispX + x1 + 2 * (x2 - x1) * divergePoint + getOffset(offset: halfOffset, options: options),
                    y: midDispY + y1 + 2 * (y2 - y1) * divergePoint + getOffset(offset: halfOffset, options: options)
                )
            ))
        } else {
            ops.append(DrawOp.bezierCurve(
                to: CGPoint(
                    x: x2 + getOffset(offset: offset, options: options),
                    y: y2 + getOffset(offset: offset, options: options)
                ),
                controlPoint1: CGPoint(
                    x: midDispX + x1 + (x2 - x1) * divergePoint + getOffset(offset: offset, options: options),
                    y: midDispY + y1 + (y2 - y1) * divergePoint + getOffset(offset: offset, options: options)
                ),
                controlPoint2: CGPoint(
                    x: midDispX + x1 + 2 * (x2 - x1) * divergePoint + getOffset(offset: offset, options: options),
                    y: midDispY + y1 + 2 * (y2 - y1) * divergePoint + getOffset(offset: offset, options: options)
                )
            ))
        }
        return ops
        
    }
    
    func pathOfDoubleLine(from: CGPoint, to: CGPoint, options: Options) -> [DrawOp] {
        var ops1 = pathOfLine(from: from, to: to, options: options, move: true, overlay: false)
        let ops2 = pathOfLine(from: from, to: to, options: options, move: true, overlay: true)
        ops1.append(contentsOf: ops2)
        return ops1
    }
    
    func pathOfEllipse(increment: Float, center: CGPoint, rx: Float, ry: Float, offset: Float, overlap: Float, options: Options) -> [DrawOp] {
        let radOffset = getOffset(offset: 0.5, options: options) - Float.pi / 2.0
        let cx = center.x.float
        let cy = center.y.float
        var points = [CGPoint]()
//        points.append(CGPoint(
//            x: getOffset(offset: offset, options: options) + cx + 0.98 * rx * cos(radOffset - increment),
//            y: getOffset(offset: offset, options: options) + cy + 0.98 * ry * sin(radOffset - increment)
//        ))
        var angle = radOffset
        while angle < (Float.pi * 2.0 + radOffset) {
            points.append(CGPoint(
                x: getOffset(offset: offset, options: options) + cx + rx * cos(angle),
                y: getOffset(offset: offset, options: options) + cy + ry * sin(angle)
            ))
            angle += increment
        }
        points.append(CGPoint(
            x: getOffset(offset: offset, options: options) + cx + rx * cos(radOffset + Float.pi * 2 + overlap * 0.5),
            y: getOffset(offset: offset, options: options) + cy + ry * sin(radOffset + Float.pi * 2 + overlap * 0.5)
        ))
        points.append(CGPoint(
            x: getOffset(offset: offset, options: options) + cx + 0.98 * rx * cos(radOffset + overlap),
            y: getOffset(offset: offset, options: options) + cy + 0.98 * ry * sin(radOffset + overlap)
        ))
        points.append(CGPoint(
            x: getOffset(offset: offset, options: options) + cx + 0.9 * rx * cos(radOffset + overlap * 0.5),
            y: getOffset(offset: offset, options: options) + cy + 0.9 * ry * sin(radOffset + overlap * 0.5)
        ))
        return pathOfCurve(points: points, closePoint: nil, options: options)
    }
    
    func pathOfCurve(points: [CGPoint], closePoint: CGPoint?, options: Options) -> [DrawOp] {
        var ops = [DrawOp]()
        let len = points.count
        if len > 3 {
            let s = Float(1.0 - options.curveTightness)
            ops.append(DrawOp.move(to: points.first!))
            for i in 1...(len-3) {
                let point = points[i]
                let nextPoint = points[i+1]
                let nextNextPoint = points[i+2]
                let prevPoint = points[i-1]
                
                let b1 = CGPoint(
                    x: point.x.float + (s * nextPoint.x.float - s * prevPoint.x.float) / 6,
                    y: point.y.float + (s * nextPoint.y.float - s * prevPoint.y.float) / 6
                )
                let b2 = CGPoint(
                    x: nextPoint.x.float + (s * point.x.float - s * nextNextPoint.x.float) / 6,
                    y: nextPoint.y.float + (s * point.y.float - s * nextNextPoint.y.float) / 6
                )
                let b3 = nextPoint
                ops.append(DrawOp.bezierCurve(to: b3, controlPoint1: b1, controlPoint2: b2))
                if let closePoint = closePoint {
                    let ro = options.maxRandomnessOffset
                    ops.append(DrawOp.move(to:
                        CGPoint(
                            x: closePoint.x.float + getOffset(offset: ro, options: options),
                            y: closePoint.y.float + getOffset(offset: ro, options: options)
                        )
                    ))
                }
            }
        } else if len == 3 {
            ops.append(DrawOp.move(to: points[1]))
            ops.append(DrawOp.bezierCurve(to: points[2], controlPoint1: points[1], controlPoint2: points[2]))
        } else if len == 2 {
            ops.append(contentsOf: pathOfDoubleLine(from: points[0], to: points[1], options: options))
        }
        return ops
    }
    
    func pathOfCurve(points: [CGPoint], offset: Float, options: Options) -> [DrawOp] {
        var ps = [CGPoint]()
        ps.append(CGPoint(
            x: points.first!.x.float + getOffset(offset: offset, options: options),
            y: points.first!.y.float + getOffset(offset: offset, options: options)
        ))
        for point in points {
            ps.append(CGPoint(
                x: point.x.float + getOffset(offset: offset, options: options),
                y: point.y.float + getOffset(offset: offset, options: options)
            ))
        }
        
        return pathOfCurve(points: ps, closePoint: nil, options: options)
    }
    
    func pathOfArc(increment: Float, cx: Float, cy: Float, rx: Float, ry: Float, strt: Float, stp: Float, offset: Float, options: Options) -> [DrawOp] {
        let radOffset = strt + getOffset(offset: 0.1, options: options)
        var points = [CGPoint]()
        //        points.append(CGPoint(
        //            x: getOffset(offset: offset, options: options) + cx + 0.9 * rx * cos(radOffset - increment),
        //            y: getOffset(offset: offset, options: options) + cy + 0.9 * ry * sin(radOffset - increment)
        //            ));
        var angle = radOffset
        while angle < stp {
            points.append(CGPoint(
                x: getOffset(offset: offset, options: options) + cx + rx * cos(angle),
                y: getOffset(offset: offset, options: options) + cy + ry * sin(angle)
            ))
            angle = angle + increment
        }
        
        points.append(CGPoint(
            x: cx + rx * cos(stp),
            y: cy + ry * sin(stp)
        ))
        points.append(CGPoint(
            x: cx + rx * cos(stp),
            y: cy + ry * sin(stp)
        ))
        
        return pathOfCurve(points: points, closePoint: nil, options: options)
    }
    
    func getOffset(min: Float, max: Float, options: Options) -> Float {
        return options.roughness * (Float.random * (max - min) + min)
    }
    
    func getOffset(offset: Float, options: Options) -> Float {
        return getOffset(min: -offset, max: offset, options: options)
    }
    
    func getIntersectingLines(lineCoords: [Float], xs: [Float], ys: [Float]) -> [CGPoint] {
        var intersections = [CGPoint]()
        var s1 = Segment(px1: lineCoords[0], py1: lineCoords[1], px2: lineCoords[2], py2: lineCoords[3])
        for i in 0...xs.count - 1 {
            let s2 = Segment(px1: xs[i], py1: ys[i], px2: xs[(i+1) % xs.count], py2: ys[(i + 1) % xs.count])
            if s1.compare(other: s2) == .intersects {
                intersections.append(CGPoint(x: s1.xi, y: s1.yi))
            }
        }
        return intersections
    }
    
    func affine(x: Float, y: Float, cx: Float, cy: Float, sinAnglePrime: Float, cosAnglePrime: Float, R: Float) -> (Float, Float) {
        let A = -cx * cosAnglePrime - cy * sinAnglePrime + cx
        let B = R * (cx * sinAnglePrime - cy * cosAnglePrime) + cy
        let C = cosAnglePrime
        let D = sinAnglePrime
        let E = -R * sinAnglePrime
        let F = R * cosAnglePrime
        return (
            A + C * x + D * y,
            B + E * x + F * y
        )
    }
}

