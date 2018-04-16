//
//  RoughCanvas.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

public typealias OptionsCallback = (Options) -> Void

@objc open class RoughCanvas: NSObject {
    public var canvasOptions = Options()
    public var renderer = Renderer()
    var paths = [Shape]()

    public override init() {}

    @objc open func draw(context _: CGContext, rect _: CGRect) {
        for shape in paths {
            switch shape {
            case let Shape.path(path: path, options: options):
                options.stroke.setStroke()
                path.lineWidth = CGFloat(options.strokeWidth)
                path.stroke()
            case let Shape.fill(path: path, options: options):
                options.fill.setFill()
                path.fill()
            case let Shape.hachure(path: path, options: options):
                options.fill.setStroke()
                path.lineWidth = CGFloat(options.fillWeight)
                path.stroke()
            case Shape.none:
                break
            }
        }
    }

    @objc public func clear() {
        paths.removeAll()
    }

    @objc public func line(from: CGPoint, to: CGPoint) {
        drawLine(from: from, to: to, options: canvasOptions)
    }

    @objc public func line(from: CGPoint, to: CGPoint, optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawLine(from: from, to: to, options: customOptions)
    }

    @objc public func rectangle(origin: CGPoint, width: Float, height: Float) {
        drawRectangle(origin: origin, width: width, height: height, options: canvasOptions)
    }

    @objc public func rectangle(origin: CGPoint, width: Float, height: Float, optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawRectangle(origin: origin, width: width, height: height, options: customOptions)
    }

    @objc public func ellipse(center: CGPoint, width: Float, height: Float) {
        drawEllipse(center: center, width: width, height: height, options: canvasOptions)
    }

    @objc public func ellipse(center: CGPoint, width: Float, height: Float, optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawEllipse(center: center, width: width, height: height, options: customOptions)
    }

    @objc public func circle(center: CGPoint, radius: Float) {
        drawEllipse(center: center, width: 2 * radius, height: 2 * radius, options: canvasOptions)
    }

    @objc public func circle(center: CGPoint, radius: Float, optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawEllipse(center: center, width: 2 * radius, height: 2 * radius, options: customOptions)
    }

    @objc public func linearPath(points: [CGPoint]) {
        drawPath(points: points, close: false, options: canvasOptions)
    }

    @objc public func linearPath(points: [CGPoint], optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawPath(points: points, close: false, options: customOptions)
    }

    @objc public func polygon(points: [CGPoint]) {
        drawPath(points: points, close: true, options: canvasOptions)
    }

    @objc public func polygon(points: [CGPoint], optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawPath(points: points, close: true, options: customOptions)
    }

    @objc public func arc(center: CGPoint, width: Float, height: Float, start: Float, stop: Float, closed: Bool) {
        drawArc(center: center, width: width, height: height, start: start, stop: stop, closed: closed, options: canvasOptions)
    }

    @objc public func curve(points: [CGPoint]) {
        drawCurve(points: points, options: canvasOptions)
    }

    @objc public func curve(points: [CGPoint], optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawCurve(points: points, options: customOptions)
    }

    @objc public func arc(center: CGPoint, width: Float, height: Float, start: Float, stop: Float, closed: Bool, optionsCallback: OptionsCallback) {
        let customOptions = Options.copy(options: canvasOptions)
        optionsCallback(customOptions)
        drawArc(center: center, width: width, height: height, start: start, stop: stop, closed: closed, options: customOptions)
    }

    func drawLine(from: CGPoint, to: CGPoint, options: Options) {
        let shape = renderer.line(from: from, to: to, options: options)
        paths.append(shape)
    }

    func drawRectangle(origin: CGPoint, width: Float, height: Float, options: Options) {
        let x = origin.x.float
        let y = origin.y.float
        var points = [CGPoint]()
        points.append(origin)
        points.append(CGPoint(x: x + width, y: y))
        points.append(CGPoint(x: x + width, y: y + height))
        points.append(CGPoint(x: x, y: y + height))

        drawPath(points: points, close: true, options: options)
    }

    func drawEllipse(center: CGPoint, width: Float, height: Float, options: Options) {
        let shape = renderer.ellipse(point: center, width: width, height: height, options: options)
        if options.fill != UIColor.clear {
            if options.fillStyle == .hachure {
                let fill = renderer.hachureFillEllipse(center: center, width: width - options.strokeWidth, height: height - options.strokeWidth, options: options)
                paths.append(fill)
            } else if case let .path(path: path, options: options) = shape {
                let fill = Shape.fill(path: path, options: options)
                paths.append(fill)
            }
        }
        paths.append(shape)
    }

    func drawPath(points: [CGPoint], close: Bool, options: Options) {
        let shape = renderer.linearPath(points: points, close: close, options: options)
        if close && options.fill != UIColor.clear {
            if options.fillStyle == .hachure {
                let fill = renderer.hachureFillShape(points: points, options: options)
                paths.append(fill)
            } else {
                let fill = renderer.solidFillShape(points: points, options: options)
                paths.append(fill)
            }
        }
        paths.append(shape)
    }

    func drawArc(center: CGPoint, width: Float, height: Float, start: Float, stop: Float, closed: Bool, options: Options) {
        let shape = renderer.arc(center: center, width: width - options.strokeWidth, height: height - options.strokeWidth, start: start, stop: stop, closed: closed, roughClosure: true, options: options)
        if options.fill != UIColor.clear {
            if options.fillStyle == .hachure {
                let fill = renderer.hachureFillArc(center: center, width: width, height: height, start: start, stop: stop, options: options)
                paths.append(fill)
            } else {
                let path = renderer.arc(center: center, width: width - options.strokeWidth, height: height - options.strokeWidth, start: start, stop: stop, closed: true, roughClosure: false, options: options)

                if case let .path(path: path, options: options) = path {
                    let fill = Shape.fill(path: path, options: options)
                    paths.append(fill)
                }
            }
        }
        paths.append(shape)
    }

    func drawCurve(points: [CGPoint], options: Options) {
        let shape = renderer.curve(points: points, options: options)
        paths.append(shape)
    }
}
