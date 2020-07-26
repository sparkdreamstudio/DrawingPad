//
//  CanvasModelProtocol.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation

protocol LoadCanvasModelProtocol: class{
    func loadCanvas(WithName name:String, completionHandler closure: @escaping (Bool,CanvasObject?)->Void)
}
protocol SaveCanvasModelProtocol : class{
    func saveCanvas(_ canvas:CanvasObject, completionHandler closure: @escaping (Bool)->Void)
}
