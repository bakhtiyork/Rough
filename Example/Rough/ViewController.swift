//
//  ViewController.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

import UIKit
import Rough

class ViewController: UIViewController {
    
    @IBOutlet var roughView: RoughView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let canvas = roughView?.canvas {
        
            // rectangle
            canvas.rectangle(origin: CGPoint(x: 10, y: 10), width: 100, height: 100)
            canvas.rectangle(origin: CGPoint(x: 140, y: 10), width: 100, height: 100) { options in
                options.fill = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.2)
                options.fillStyle = .solid
                options.roughness = 2
            }
            canvas.rectangle(origin: CGPoint(x: 10, y: 130), width: 100, height: 100) { options in
                options.fill = UIColor.red
                options.stroke = UIColor.blue
                options.hachureAngle = 60
                options.hachureGap = 10
                options.fillWeight = 5
                options.strokeWidth = 5
            }
            
            // ellipse and circle
            canvas.ellipse(center: CGPoint(x: 350, y: 50), width: 150, height: 80)
            canvas.ellipse(center: CGPoint(x: 610, y: 50), width: 150, height: 80) { options in
                options.fill = UIColor.blue
            }
            canvas.circle(center: CGPoint(x: 480, y: 50), radius: 40) { options in
                options.stroke = UIColor.red
                options.strokeWidth = 2
                options.fill = UIColor(red: 0, green: 1.0, blue: 0, alpha: 0.3)
                options.fillStyle = .solid
            }
            
            // overlapping circles
            canvas.circle(center: CGPoint(x: 480, y: 150), radius: 40) { options in
                options.stroke = UIColor.red
                options.strokeWidth = 4
                options.fill = UIColor(red: 0, green: 1.0, blue: 0, alpha: 1)
                options.fillWeight = 4
                options.hachureGap = 6
            }
            canvas.circle(center: CGPoint(x: 530, y: 150), radius: 40) { options in
                options.stroke = UIColor.blue
                options.strokeWidth = 4
                options.fill = UIColor(red: 1.0, green: 1.0, blue: 0, alpha: 1)
                options.fillWeight = 4
                options.hachureGap = 6
            }
            
            // linearPath and polygon
            canvas.linearPath(points: [CGPoint(x: 690, y:10), CGPoint(x: 790, y: 20), CGPoint(x: 750, y: 120), CGPoint(x: 690, y:100)]) { options in
                options.roughness = 0.7
                options.stroke = UIColor.red
                options.strokeWidth = 4
            }
            canvas.polygon(points: [CGPoint(x: 690, y:130), CGPoint(x: 790, y: 140), CGPoint(x: 750, y: 240), CGPoint(x: 690, y:220)])
            canvas.polygon(points: [CGPoint(x: 690, y:250), CGPoint(x: 790, y: 260), CGPoint(x: 750, y: 360), CGPoint(x: 690, y:340)]) { options in
                options.stroke = UIColor.red
                options.strokeWidth = 4
                options.fill = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.2)
                options.fillStyle = .solid
            }
            canvas.polygon(points: [CGPoint(x: 690, y:370), CGPoint(x: 790, y: 385), CGPoint(x: 750, y: 480), CGPoint(x: 690, y:460)]) { options in
                options.stroke = UIColor.red
                options.fill = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.6)
                options.hachureAngle = 65
            }
            
            // arcs
            canvas.arc(center: CGPoint(x: 350, y: 200), width: 200, height: 180, start: Float.pi, stop: Float.pi * 1.6, closed: false)
            canvas.arc(center: CGPoint(x: 350, y: 300), width: 200, height: 180, start: Float.pi, stop: Float.pi * 1.6, closed: true)
            canvas.arc(center: CGPoint(x: 350, y: 300), width: 200, height: 180, start: 0, stop: Float.pi / 2, closed: true) { options in
                options.stroke = UIColor.red
                options.strokeWidth = 4
                options.fill = UIColor(red: 1, green: 1, blue: 0, alpha: 0.4)
                options.fillStyle = .solid
            }
            canvas.arc(center: CGPoint(x: 350, y: 300), width: 200, height: 180, start: Float.pi / 2, stop: Float.pi, closed: true) { options in
                options.stroke = UIColor.blue
                options.strokeWidth = 2
                options.fillWeight = 4
                options.fill = UIColor(red: 1, green: 0, blue: 1, alpha: 0.4)
            }
            
            // draw sine curve
            var points = [CGPoint]()
            for i in 0...20 {
                let x = (400.0 / 20.0) * Double(i) + 10.0
                let xdeg = (Double.pi / 100.0) * x
                let y = round(sin(xdeg) * 90.0) + 500.0
                points.append(CGPoint(x: x, y: y))
            }
            canvas.curve(points: points) { options in
                options.roughness = 1.2
                options.stroke = UIColor.red
                options.strokeWidth = 3
            }
            
            roughView?.setNeedsDisplay()
        }
    }
}

