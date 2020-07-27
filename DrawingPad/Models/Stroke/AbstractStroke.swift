//
//  AbstractBrush.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit

struct StrokeRaw : Codable{
    var type:String
    var points:[StrokePoint]
    var created:Date
    var color:StrokeColor
    var width:CGFloat
}
struct StrokePoint : Codable{
    var x:CGFloat = 0
    var y:CGFloat = 0
    var cgPoint:CGPoint{
        set{
            x = newValue.x
            y = newValue.y
        }
        get{
            return CGPoint(x: x, y: y)
        }
    }
}

struct StrokeColor: Codable {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat?
    var uiColor: UIColor {
        set(newColor) {
            let ciColor = CIColor(color: newColor)
            self = StrokeColor(red: ciColor.red, green: ciColor.green, blue: ciColor.blue, alpha: ciColor.alpha)
        }
        get{
            return UIColor(red: red, green: green, blue: blue, alpha: alpha ?? 1)
        }
        
    }
    static var black : StrokeColor{
        get{
            var color = StrokeColor(red: 0, green: 0, blue: 0, alpha: 0)
            color.uiColor = UIColor.black
            return color
        }
    }
}

protocol AbstractStroke {
    var color:UIColor {get set}
    var width:CGFloat {get set}
    var created:Date {get set}
    var points:[CGPoint] {get set}
    func isConinuous() -> Bool
    func isCompleted() -> Bool
    mutating func addPoint(_ point:CGPoint)
    func drawRelativeOrigin(_ origin:CGPoint,onContext context:CGContext?) -> Void
    func getRawData() -> StrokeRaw
}

