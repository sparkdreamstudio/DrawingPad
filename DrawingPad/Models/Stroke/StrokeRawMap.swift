//
//  StrokeRawMap.swift
//  DrawingPad
//
//  Created by xiang on 7/27/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit
func getStrokeFrom(raw:StrokeRaw) -> AbstractStroke?{
    switch raw.type {
    case String(describing: CurveStroke.self):
        var cgPoints = [CGPoint]()
        for point in raw.points{
            cgPoints.append(point.cgPoint)
        }
        return CurveStroke(created: raw.created, color: raw.color.uiColor, width: raw.width, points: cgPoints,count: 0)
    case String(describing: EraserStroke.self):
        var cgPoints = [CGPoint]()
        for point in raw.points{
            cgPoints.append(point.cgPoint)
        }
        return EraserStroke(created: raw.created, color: raw.color.uiColor, width: raw.width, points: cgPoints,count: 0)
    default:
        return nil
    }
}
