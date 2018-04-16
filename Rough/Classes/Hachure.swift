//
//  Hachure.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

enum SegmentRelation {
    case intersects, separate, undefined
}

let MIN_LIMIT: Float = 0.0001
let MAX_LIMIT: Float = 0.9999

struct Segment {
    var px1: Float = 0
    var py1: Float = 0
    var px2: Float = 0
    var py2: Float = 0
    var xi: Float = MAXFLOAT
    var yi: Float = MAXFLOAT
    var a: Float = 0
    var b: Float = 0
    var c: Float = 0
    var undefinded: Bool = false

    init(px1: Float, py1: Float, px2: Float, py2: Float) {
        self.px1 = px1
        self.py1 = py1
        self.px2 = px2
        self.py2 = py2
        a = py2 - py1
        b = px1 - px2
        c = px2 * py1 - px1 * py2
        undefinded = (a == 0) && (b == 0) && (c == 0)
    }

    mutating func compare(other: Segment) -> SegmentRelation {
        if undefinded || other.undefinded {
            return .undefined
        }
        var grad1 = MAXFLOAT
        var grad2 = MAXFLOAT
        var int1: Float = 0
        var int2: Float = 0

        if abs(b) > MIN_LIMIT {
            grad1 = -a / b
            int1 = -c / b
        }
        if abs(other.b) > MIN_LIMIT {
            grad2 = -other.a / other.b
            int2 = -other.c / other.b
        }

        if grad1 == MAXFLOAT {
            if grad2 == MAXFLOAT {
                if (-c / a) != (-other.c / other.a) {
                    return .separate
                }
                if (py1 >= min(other.py1, other.py2)) && (py1 <= max(other.py1, other.py2)) {
                    xi = px1
                    yi = py1
                    return .intersects
                }
                if (py2 >= min(other.py1, other.py2)) && (py2 <= max(other.py1, other.py2)) {
                    xi = px2
                    yi = py2
                    return .intersects
                }
                return .separate
            }
            xi = px1
            yi = grad2 * xi + int2
            if ((py1 - yi) * (yi - py2) < -MIN_LIMIT) || ((other.py1 - yi) * (yi - other.py2) < -MIN_LIMIT) {
                return .separate
            }
            if abs(other.a) < MIN_LIMIT {
                if (other.px1 - xi) * (xi - other.px2) < -MIN_LIMIT {
                    return .separate
                }
                return .intersects
            }
            return .intersects
        }

        if grad2 == MAXFLOAT {
            xi = other.px1
            yi = grad1 * xi + int1
            if ((other.py1 - yi) * (yi - other.py2) < -MIN_LIMIT) || ((py1 - yi) * (yi - py2) < -MIN_LIMIT) {
                return .separate
            }
            if abs(a) < MIN_LIMIT {
                if (px1 - xi) * (xi - px2) < -MIN_LIMIT {
                    return .separate
                }
                return .intersects
            }
            return .intersects
        }

        if grad1 == grad2 {
            if int1 != int2 {
                return .separate
            }
            if (px1 >= min(other.px1, other.px2)) && (px1 <= max(other.py1, other.py2)) {
                xi = px1
                yi = py1
                return .intersects
            }
            if (px2 >= min(other.px1, other.px2)) && (px2 <= max(other.px1, other.px2)) {
                xi = px2
                yi = py2
                return .intersects
            }
            return .separate
        }

        xi = (int2 - int1) / (grad1 - grad2)
        yi = grad1 * xi + int1

        if ((px1 - xi) * (xi - px2) < -MIN_LIMIT) || ((other.px1 - xi) * (xi - other.px2) < -MIN_LIMIT) {
            return .separate
        }
        return .intersects
    }

    func getLength() -> Float {
        let dx = px2 - px1
        let dy = py2 - py1
        return sqrt(dx * dx + dy * dy)
    }
}

class HachureIterator: IteratorProtocol {
    let top: Float
    let bottom: Float
    let left: Float
    let right: Float
    let gap: Float
    let sinAngle: Float
    let tanAngle: Float
    var pos: Float = 0
    var deltaX: Float = 0
    var hGap: Float = 0
    var sLeft: Segment?
    var sRight: Segment?

    init(top: Float, bottom: Float, left: Float, right: Float, gap: Float, sinAngle: Float, cosAngle: Float, tanAngle: Float) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.gap = gap
        self.sinAngle = sinAngle
        self.tanAngle = tanAngle

        if abs(sinAngle) < MIN_LIMIT {
            pos = left + gap
        } else if abs(sinAngle) > MAX_LIMIT {
            pos = top + gap
        } else {
            deltaX = (bottom - top) * abs(tanAngle)
            pos = left - abs(deltaX)
            hGap = abs(gap / cosAngle)
            sLeft = Segment(px1: left, py1: bottom, px2: left, py2: top)
            sRight = Segment(px1: right, py1: bottom, px2: right, py2: top)
        }
    }

    func next() -> [Float]? {
        if abs(sinAngle) < MIN_LIMIT {
            if pos < right {
                let line = [pos, top, pos, bottom]
                pos += gap
                return line
            }
        } else if abs(sinAngle) > MAX_LIMIT {
            if pos < bottom {
                let line = [left, pos, right, pos]
                pos += gap
                return line
            }
        } else {
            var xLower = pos - deltaX / 2.0
            var xUpper = pos + deltaX / 2.0
            var yLower = bottom
            var yUpper = top
            if pos < (right + deltaX) {
                while (xLower < left && xUpper < left) || (xLower > right && xUpper > right) {
                    pos += hGap
                    xLower = pos - deltaX / 2.0
                    xUpper = pos + deltaX / 2.0
                    if pos > (right + deltaX) {
                        return nil
                    }
                }
                var s = Segment(px1: xLower, py1: yLower, px2: xUpper, py2: yUpper)
                if sLeft != nil && s.compare(other: sLeft!) == .intersects {
                    xLower = s.xi
                    yLower = s.yi
                }
                if sRight != nil && s.compare(other: sRight!) == .intersects {
                    xUpper = s.xi
                    yUpper = s.yi
                }
                if tanAngle > 0 {
                    xLower = right - (xLower - left)
                    xUpper = right - (xUpper - left)
                }
                let line = [xLower, yLower, xUpper, yUpper]
                pos += hGap
                return line
            }
        }
        return nil
    }
}
