//
//  CanvasModelProtocol.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation

protocol LoadAndDeleteCanvasModelProtocol: class{
    func loadCanvas(WithName name:String, completionHandler closure: @escaping (Bool,CanvasObject?)->Void)
    func deleteCanvas(_ canvasName:String, completionHandler closure: @escaping (Bool)->Void)
}
protocol ModifyCanvasModelProtocol : class{
    func saveCanvas(_ canvas:CanvasObject, completionHandler closure: @escaping (Bool)->Void)
    
}
