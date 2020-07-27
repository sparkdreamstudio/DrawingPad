//
//  CurveStroke.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit


struct CurveStroke:AbstractStroke{
    var created: Date = Date()
    var color: UIColor = .clear
    var width: CGFloat = 0
    var points = [CGPoint](repeating: CGPoint(), count: 5)
    var count = 0
    func isConinuous() -> Bool {
        return true
    }
    
    func isCompleted() -> Bool {
        return count == 5
    }
    
    mutating func addPoint(_ point: CGPoint) {
        if(count == 5){
            points[0] = points[3];
            points[1] = points[4];
            count = 2
        }
        points[count] = point
        count += 1
        if(count == 5){
            points[3] = CGPoint(x: (points[2].x + points[4].x)/2,
                                y: (points[2].y + points[4].y)/2)
        }
        
    }
    func drawRelativeOrigin(_ origin:CGPoint,onContext context: CGContext?) {
        context?.setBlendMode(.normal)
        context?.setLineWidth(width)
        context?.setStrokeColor(self.color.cgColor)
        context?.move(to: CGPoint(x: points[0].x-origin.x,
                                  y: points[0].y-origin.y))
        context?.addCurve(to: CGPoint(x: points[3].x-origin.x,
                                      y: points[3].y-origin.y),
                          control1: CGPoint(x: points[1].x-origin.x,
                                            y: points[1].y-origin.y),
                          control2: CGPoint(x: points[2].x-origin.x,
                                            y: points[2].y-origin.y))
        context?.strokePath()
    }
    
    func getRawData() -> StrokeRaw{
        var strokePoints = [StrokePoint]()
        for point in points{
            var strokePoint = StrokePoint()
            strokePoint.cgPoint = point
            strokePoints.append(strokePoint)
        }
        var color = StrokeColor()
        color.uiColor = self.color
        return StrokeRaw(type: String(describing: CurveStroke.self), points: strokePoints, created: created, color: color, width: self.width)
    }

}
