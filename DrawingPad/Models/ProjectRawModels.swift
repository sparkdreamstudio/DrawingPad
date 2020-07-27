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
    var canvasdelegate: (LoadAndDeleteCanvasModelProtocol & ModifyCanvasModelProtocol)?
    
    subscript(index:Int) -> CanvasBrife?{
        if index >= count
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
    
    func deleteCanvas(at index:Int, completionHandler closure:@escaping (Bool)->Void){
        if(index < count){
            let brife = brifes[index]
            brifes.remove(at: index);
            projectdelegate?.saveModel(brifes, closure: { [weak self] (success) in
                if success == true{
                    self?.canvasdelegate?.deleteCanvas(brife.unique_name, completionHandler: { (success) in
                        if success == true{
                            DispatchQueue.main.async {
                                closure(success)
                            }
                        }
                        else{
                            self?.brifes.insert(brife, at: index)
                            DispatchQueue.main.async {
                                closure(false)
                            }
                        }
                    })
                }
                else{
                    self?.brifes.insert(brife, at: index)
                    DispatchQueue.main.async {
                        closure(false)
                    }
                }
            })
            
        }
        else{
            closure(false)
        }
        
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
    func openCanvas(at index:Int, completionHandler closure: @escaping (Bool,CanvasObject?)->Void ) -> Void {
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
    var draws:[CanvasObject.Operation]
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
        var color:StrokeColor
    }
    
    struct Operation : Codable {
        var uuid:String = NSUUID().uuidString
        var strokes:[StrokeRaw] = [StrokeRaw]()
    }
    private enum Status : UInt8{
        case idle = 0b00000000
        case drawing = 0b00000001
        case recording = 0b00000010
        case playing = 0b00000100
    }
    
    //MARK: Canvas Data
    var name:String
    private var draws:[Operation]
    private var drawsRecord : [[String]]
    var size:CGSize
    
    //MARK: Operation properties
    private var status:UInt8 = Status.idle.rawValue
    private var brush:Brush = Brush(width: 1, color: .black)
    
    //MARK: Delegate
    weak var savedelegate:ModifyCanvasModelProtocol?
    weak var drawingDelegate:CanvasModelDelegate?
    
    init() {
        name = NSUUID().uuidString
        drawsRecord=[[String]]()
        draws = [Operation]()
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
    mutating func startDrawing(){
        status = status | Status.drawing.rawValue
        let drawing = Operation()
        draws.append(drawing)
        if(status & Status.recording.rawValue > 0){
            drawsRecord.append([String]())
            drawsRecord[drawsRecord.count-1].append(drawing.uuid)
        }
    }
    mutating func addStrokes(_ strokes:[StrokeRaw]){
        if status & Status.drawing.rawValue > 0 {
            draws[draws.count-1].strokes = draws[draws.count-1].strokes+strokes
            drawingDelegate?.getStrokes(strokes)
        }
    }
    mutating func endDrawing(WithStroke stroke:StrokeRaw?){
        status = status & (~Status.drawing.rawValue)
        if let _stroke = stroke{
            draws[draws.count-1].strokes.append(_stroke)
        }
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
        var strokes = [StrokeRaw]()
        for draw in draws{
            for _stroke in draw.strokes{
                strokes.append(_stroke)
            }
        }
        drawingDelegate?.getStrokes(strokes)
    }
}

protocol CanvasModelDelegate : class {
    func getStrokes(_ strokes:[StrokeRaw])
}
