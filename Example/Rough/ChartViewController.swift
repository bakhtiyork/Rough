//
//  ChartViewController.swift
//  Rough
//
//  Copyright (c) 2018. MIT License
//  https://github.com/bakhtiyork/Rough
//

import UIKit
import Rough
import Charts

class ChartViewController : UIViewController {
    
    @IBOutlet var barView: BarChartView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let barView = self.barView {
            let oldRenderer = barView.renderer!
            barView.renderer = RoughBarChartRenderer(dataProvider: barView, animator: oldRenderer.animator, viewPortHandler: oldRenderer.viewPortHandler)
            updateChartWithData()
            barView.chartDescription?.text = ""
        }
    }
    
    func updateChartWithData() {
        var dataEntries: [BarChartDataEntry] = []
        let count = 5
        for i in 0..<count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(arc4random_uniform(20)))
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Random values")
        chartDataSet.colors = [UIColor.blue, UIColor.darkGray, UIColor.red, UIColor.green, UIColor.orange]
        let chartData = BarChartData(dataSet: chartDataSet)
        barView?.data = chartData
    }
}


class RoughBarChartRenderer : BarChartRenderer {
    private class Buffer
    {
        var rects = [CGRect]()
    }
    
    private var _buffers = [Buffer]()
    
    open override func initBuffers()
    {
        super.initBuffers()
        if let barData = dataProvider?.barData
        {
            // Matche buffers count to dataset count
            if _buffers.count != barData.dataSetCount
            {
                while _buffers.count < barData.dataSetCount
                {
                    _buffers.append(Buffer())
                }
                while _buffers.count > barData.dataSetCount
                {
                    _buffers.removeLast()
                }
            }
            
            for i in stride(from: 0, to: barData.dataSetCount, by: 1)
            {
                let set = barData.dataSets[i] as! IBarChartDataSet
                let size = set.entryCount * (set.isStacked ? set.stackSize : 1)
                if _buffers[i].rects.count != size
                {
                    _buffers[i].rects = [CGRect](repeating: CGRect(), count: size)
                }
            }
        }
        else
        {
            _buffers.removeAll()
        }
    }
    
    private func prepareBuffer(dataSet: IBarChartDataSet, index: Int)
    {
        guard
            let dataProvider = dataProvider,
            let barData = dataProvider.barData
            else { return }
        
        let barWidthHalf = barData.barWidth / 2.0
        
        let buffer = _buffers[index]
        var bufferIndex = 0
        let containsStacks = dataSet.isStacked
        
        let isInverted = dataProvider.isInverted(axis: dataSet.axisDependency)
        let phaseY = animator.phaseY
        var barRect = CGRect()
        var x: Double
        var y: Double
        
        for i in stride(from: 0, to: min(Int(ceil(Double(dataSet.entryCount) * animator.phaseX)), dataSet.entryCount), by: 1)
        {
            guard let e = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }
            
            let vals = e.yValues
            
            x = e.x
            y = e.y
            
            if !containsStacks || vals == nil
            {
                let left = CGFloat(x - barWidthHalf)
                let right = CGFloat(x + barWidthHalf)
                var top = isInverted
                    ? (y <= 0.0 ? CGFloat(y) : 0)
                    : (y >= 0.0 ? CGFloat(y) : 0)
                var bottom = isInverted
                    ? (y >= 0.0 ? CGFloat(y) : 0)
                    : (y <= 0.0 ? CGFloat(y) : 0)
                
                // multiply the height of the rect with the phase
                if top > 0
                {
                    top *= CGFloat(phaseY)
                }
                else
                {
                    bottom *= CGFloat(phaseY)
                }
                
                barRect.origin.x = left
                barRect.size.width = right - left
                barRect.origin.y = top
                barRect.size.height = bottom - top
                
                buffer.rects[bufferIndex] = barRect
                bufferIndex += 1
            }
            else
            {
                var posY = 0.0
                var negY = -e.negativeSum
                var yStart = 0.0
                
                // fill the stack
                for k in 0 ..< vals!.count
                {
                    let value = vals![k]
                    
                    if value == 0.0 && (posY == 0.0 || negY == 0.0)
                    {
                        // Take care of the situation of a 0.0 value, which overlaps a non-zero bar
                        y = value
                        yStart = y
                    }
                    else if value >= 0.0
                    {
                        y = posY
                        yStart = posY + value
                        posY = yStart
                    }
                    else
                    {
                        y = negY
                        yStart = negY + abs(value)
                        negY += abs(value)
                    }
                    
                    let left = CGFloat(x - barWidthHalf)
                    let right = CGFloat(x + barWidthHalf)
                    var top = isInverted
                        ? (y <= yStart ? CGFloat(y) : CGFloat(yStart))
                        : (y >= yStart ? CGFloat(y) : CGFloat(yStart))
                    var bottom = isInverted
                        ? (y >= yStart ? CGFloat(y) : CGFloat(yStart))
                        : (y <= yStart ? CGFloat(y) : CGFloat(yStart))
                    
                    // multiply the height of the rect with the phase
                    top *= CGFloat(phaseY)
                    bottom *= CGFloat(phaseY)
                    
                    barRect.origin.x = left
                    barRect.size.width = right - left
                    barRect.origin.y = top
                    barRect.size.height = bottom - top
                    
                    buffer.rects[bufferIndex] = barRect
                    bufferIndex += 1
                }
            }
        }
    }
    
    override func drawDataSet(context: CGContext, dataSet: IBarChartDataSet, index: Int)
    {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        prepareBuffer(dataSet: dataSet, index: index)
        trans.rectValuesToPixel(&_buffers[index].rects)
        
        let borderWidth = max(dataSet.barBorderWidth, 1)
        let borderColor = dataSet.barBorderColor
        
        let canvas = RoughCanvas()
        
        context.saveGState()
        
        let buffer = _buffers[index]
        
        let isSingleColor = dataSet.colors.count == 1
        
        if isSingleColor
        {
            context.setFillColor(dataSet.color(atIndex: 0).cgColor)
        }
        
        for j in stride(from: 0, to: buffer.rects.count, by: 1)
        {
            let barRect = buffer.rects[j]
            
            if (!viewPortHandler.isInBoundsLeft(barRect.origin.x + barRect.size.width))
            {
                continue
            }
            
            if (!viewPortHandler.isInBoundsRight(barRect.origin.x))
            {
                break
            }
            
            if !isSingleColor
            {
                // Set the color for the currently drawn value. If the index is out of bounds, reuse colors.
                context.setFillColor(dataSet.color(atIndex: j).cgColor)
            }
            
            canvas.rectangle(origin: barRect.origin, width: Float(barRect.size.width), height: Float(barRect.size.height)) { options in
                options.fillStyle = .hachure
                options.fill = dataSet.color(atIndex: j)
                options.fillWeight = 4
                options.hachureGap = 6
                options.stroke = UIColor.clear
            }

            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)
            context.stroke(barRect)
        }
        
        canvas.draw(context: context, rect: CGRect(x: 0, y: 0, width: context.width, height: context.height))
        
        context.restoreGState()
    }
    
}
