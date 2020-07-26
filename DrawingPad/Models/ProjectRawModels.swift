//
//  ProjectRawModels.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit

var dispathQueueForFileOperation = DispatchQueue(label: "com.xiang.fileOperation")

struct CanvasBrife : Codable{
    var unique_name:String
    var createdTime:String
    var workingDuration:String
}

struct ProjectsManager{
    var brifes:[CanvasBrife]
    var projectdelegate:ProjectManagerProtocol
    var canvasdelegate: LoadCanvasModelProtocol&SaveCanvasModelProtocol
}

struct CanvasObject{
    struct Brush{
        
    }
    struct Stroke : Codable {
        
    }
    struct ContinousDrawing : Codable {
        
    }
    enum Status{
        case drawing
        case recording
        case playing
    }
    var name:String
    var brush:Brush
    var draws:[ContinousDrawing]
    var drawsRecord : [[String]]
    var size:CGSize
    var status:Status
    
    weak var savedelegate:SaveCanvasModelProtocol?
    mutating func addCurve(withPoints points:[CGPoint]){
        
    }
    mutating func startRecord(){
        
    }
    mutating func stopRecord(){
        
    }
    mutating func play(){
        
    }
    func redraw(_ rect:CGRect){
        
    }
}

protocol CanvasObjectDelegate : class {
    
}
