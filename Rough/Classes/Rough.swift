//
//  Rough.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

public typealias BezierPath = UIBezierPath

extension CGFloat {
    public var float: Float {
        return Float(self)
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension String {
    mutating func removingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }
}

extension Float {
    public static var random: Float {
        return Float(arc4random()) / 0xFFFFFFFF
    }
}

extension CGPoint {
    init(x: Float, y: Float) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
    init(pair: (Float, Float)) {
        self.init(x: CGFloat(pair.0), y: CGFloat(pair.1))
    }
}

public enum DrawOp {
    case move(to: CGPoint)
    case bezierCurve(to: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint)
    case quadCurve(to: CGPoint,
        controlPoint: CGPoint)
    case line(to: CGPoint)
}

public enum Shape {
    case none
    case path(path: BezierPath, options: Options)
    case fill(path: BezierPath, options: Options)
    case hachure(path: BezierPath, options: Options)
    
    static func toBezierPath(ops: [DrawOp], closed: Bool) -> BezierPath {
        let bezierPath = BezierPath()
        for op in ops {
            switch op {
            case .move(to: let point):
                bezierPath.move(to: point)
            case .bezierCurve(to: let origin, controlPoint1: let point1, controlPoint2: let point2):
                bezierPath.addCurve(to: origin, controlPoint1: point1, controlPoint2: point2)
            case .quadCurve(to: let origin, controlPoint: let point):
                bezierPath.addQuadCurve(to: origin, controlPoint: point)
            case .line(to: let point):
                bezierPath.addLine(to: point)
            }
        }
        if closed {
            bezierPath.close()
        }
        return bezierPath
    }
}

public enum FillType {
    case hachure, solid
}

@objc public class Options: NSObject {
    override init() {}
    
    public var maxRandomnessOffset: Float = 2.0
    public var bowing: Float = 1.0
    public var roughness: Float = 1.0
    public var stroke = UIColor.black
    public var strokeWidth: Float = 1.0
    public var curveTightness: Float = 0.0
    public var curveStepCount = 9
    public var fill = UIColor.clear
    public var fillStyle = FillType.hachure
    public var fillWeight: Float = 1.0
    public var hachureAngle: Float = -41.0
    public var hachureGap: Float = -1.0
    public var simplification: Bool = false
    
    static public func copy(options: Options) -> Options {
        let copy = Options()
        copy.maxRandomnessOffset = options.maxRandomnessOffset
        copy.bowing = options.bowing
        copy.roughness = options.roughness
        copy.stroke = options.stroke
        copy.strokeWidth = options.strokeWidth
        copy.curveTightness = options.curveTightness
        copy.curveStepCount = options.curveStepCount
        copy.fill = options.fill
        copy.fillStyle = options.fillStyle
        copy.fillWeight = options.fillWeight
        copy.hachureAngle = options.hachureAngle
        copy.hachureGap = options.hachureGap
        copy.simplification = options.simplification
        return copy
    }
}

