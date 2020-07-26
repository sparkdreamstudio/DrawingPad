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
    var createdTime:Date=Date()
    var workingDuration:Int=0
}

class ProjectsManager{
    private var brifes:[CanvasBrife]=[CanvasBrife]()
    var projectdelegate:ProjectsControlProtocol?
    var canvasdelegate: (LoadCanvasModelProtocol & SaveCanvasModelProtocol)?
    
    subscript(index:Int) -> CanvasBrife?{
        if index > count
        {
            return nil
        }
        return brifes[index]
    }
    var count:Int {
        return brifes.count
    }
    
    func addCanvas(modelSaveFinishedHandler closureModel:@escaping (Bool)->Void, canvasSaveFinishedHandler closureCanvas:@escaping (Bool, CanvasObject?)->Void){
        var canvasObject = CanvasObject()
        canvasObject.savedelegate = canvasdelegate
        let brife = CanvasBrife(unique_name: canvasObject.name)
        brifes.append(brife)
        projectdelegate?.saveModel(brifes, closure: { (success) in
            DispatchQueue.main.async {
                closureModel(success)
            }
        })
        canvasdelegate?.saveCanvas(canvasObject, completionHandler: { (success) in
            DispatchQueue.main.async {
                closureCanvas(success, success == true ? canvasObject : nil)
                
            }
        })
    }
    
    func openProjects(completionHandler closure: @escaping (Bool)->Void){
        projectdelegate?.loadModel { [weak self] (success, _brifes) in
            if let nonNilBrifes = _brifes{
                self?.brifes = nonNilBrifes
                DispatchQueue.main.async {
                    closure(success)
                }
            }
            else{
                DispatchQueue.main.async {
                    closure(false)
                }
            }
            
        }
    }
    func openCanvas(at index:Int,With delegate:CanvasDrawingDelegate, completionHandler closure: @escaping (Bool,CanvasObject?)->Void ) -> Void {
        if index < count {
            canvasdelegate?.loadCanvas(WithName: self.brifes[index].unique_name) { (success, canvas) in
                var localcanvas = canvas
                localcanvas?.savedelegate = self.canvasdelegate
                DispatchQueue.main.async {
                    closure(success,localcanvas)
                }
            }
        }
        else{
            DispatchQueue.main.async {
                closure(false,nil)
            }
        }
    }
    
}

struct CanvasRawData: Codable{
    var draws:[CanvasObject.ContinuousDrawing]
    var drawsRecord : [[String]]
    var height:CGFloat
    var width:CGFloat
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
}

struct CanvasObject{
    private struct Brush{
        var width:CGFloat
        var color:Color
    }
    struct Color: Codable {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat?

        var uiColor: UIColor {
            set(newColor) {
                self = Color(red: newColor.ciColor.red, green: newColor.ciColor.green, blue: newColor.ciColor.blue, alpha: newColor.ciColor.alpha)
            }
            get{
                return UIColor(red: red, green: green, blue: blue, alpha: alpha ?? 1)
            }
            
        }
        static var black : Color{
            get{
                var color = Color(red: 0, green: 0, blue: 0, alpha: 0)
                color.uiColor = UIColor.black
                return color
            }
        }
    }
    
    struct Stroke : Codable {
        var curveStart:Point
        var curveEnd:Point
        var curveControl1:Point
        var curveControl2:Point
        var width:CGFloat
        var color:Color
        var time:Date = Date()
    }
    struct Point: Codable{
        var x:CGFloat
        var y:CGFloat
        init(cgPoint:CGPoint) {
            x = cgPoint.x
            y = cgPoint.y
        }
    }
    struct ContinuousDrawing : Codable {
        var uuid:String = NSUUID().uuidString
        var strokes:[Stroke] = [Stroke]()
    }
    private enum Status : UInt8{
        case idle = 0b00000000
        case drawing = 0b00000001
        case recording = 0b00000010
        case playing = 0b00000100
    }
    
    //MARK: Canvas Data
    var name:String
    private var draws:[ContinuousDrawing]
    private var drawsRecord : [[String]]
    var size:CGSize
    
    //MARK: Operation properties
    private var status:UInt8 = Status.idle.rawValue
    private var brush:Brush = Brush(width: 1, color: .black)
    
    //MARK: Delegate
    weak var savedelegate:SaveCanvasModelProtocol?
    weak var drawingDelegate:CanvasDrawingDelegate?
    
    init() {
        name = NSUUID().uuidString
        drawsRecord=[[String]]()
        draws = [ContinuousDrawing]()
        size = CGSize(width: 2000, height: 2000)
    }
    init(withName fileName:String, andRawData rawData:CanvasRawData) {
        name = fileName
        draws = rawData.draws
        drawsRecord = rawData.drawsRecord
        size = CGSize(width: rawData.width, height: rawData.height)
    }
    
    func exportRawData() -> CanvasRawData{
        let rawData = CanvasRawData(draws: draws, drawsRecord: drawsRecord, height: size.height, width: size.width)
        return rawData
    }
    mutating func setBrushColor(_ color:UIColor){
        brush.color.uiColor = color
    }
    mutating func setBrushWidth(_ width:CGFloat){
        
        brush.width = width
    }
    mutating func startContinuousDrawing(){
        status = status | Status.drawing.rawValue
        let drawing = ContinuousDrawing()
        draws.append(drawing)
        if(status & Status.recording.rawValue > 0){
            drawsRecord.append([String]())
            drawsRecord[drawsRecord.count-1].append(drawing.uuid)
        }
    }
    mutating func addCurve(withPoints points:[CGPoint]){
        if status & Status.drawing.rawValue > 0 {
            let stroke = Stroke(curveStart: Point(cgPoint: points[0]), curveEnd: Point(cgPoint: points[3]), curveControl1: Point(cgPoint: points[1]), curveControl2: Point(cgPoint: points[2]), width: self.brush.width, color: brush.color)
            draws[draws.count-1].strokes.append(stroke)
            drawingDelegate?.getStrokes([stroke])
        }
    }
    mutating func endContinousDrawing(){
        status = status & (~Status.drawing.rawValue)
        savedelegate?.saveCanvas(self, completionHandler: { (success) in
            
        })
    }
    mutating func startRecord(){
        status = status | Status.recording.rawValue
    }
    mutating func stopRecord(){
        status = status & (~Status.recording.rawValue)
    }
    mutating func play(){
        status = Status.playing.rawValue
    }
    mutating func stop(){
        status = Status.idle.rawValue
    }
    func redraw(_ rect:CGRect){
        drawingDelegate?.getStrokes(draws.flatMap({ (draw) -> [Stroke] in
            return draw.strokes
        }))
    }
}

protocol CanvasDrawingDelegate : class {
    func getStrokes(_ strokes:[CanvasObject.Stroke])
}
