//
//  RoughView.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

@objc open class RoughView: UIView {
    @objc public var canvas = RoughCanvas()

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @objc open override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            if isOpaque, let backgroundColor = self.backgroundColor {
                backgroundColor.setFill()
                context.fill(rect)
            }
            context.setLineJoin(.bevel)
            context.setLineCap(.round)
            canvas.draw(context: context, rect: rect)
            context.restoreGState()
        }
    }
}
