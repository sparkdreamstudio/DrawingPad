//
//  CanvasObject.swift
//  DrawingPad
//
//  Created by xiang on 7/27/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit
struct CanvasRawData: Codable{
    var draws:[CanvasObject.Operation]
    var drawsRecord : [String]
    var height:CGFloat
    var width:CGFloat
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
}

class CanvasObject{
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
    private var drawsRecord : [String]
    var size:CGSize
    
    //MARK: Operation properties
    private var status:UInt8 = Status.idle.rawValue
    private var brush:Brush = Brush(width: 1, color: .black)
    private var lastOperationTime:Double = 0
    
    //MARK: Delegate
    weak var savedelegate:ModifyCanvasModelProtocol?
    weak var drawingDelegate:CanvasModelDelegate?
    
    
    
    init() {
        name = NSUUID().uuidString
        drawsRecord=[String]()
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
    func setBrushColor(_ color:UIColor){
        brush.color.uiColor = color
    }
    func setBrushWidth(_ width:CGFloat){
        
        brush.width = width
    }
    func startDrawing(){
        status = status | Status.drawing.rawValue
        let drawing = Operation()
        draws.append(drawing)
        if(status & Status.recording.rawValue > 0){
            drawsRecord.append(drawing.uuid)
        }
        if lastOperationTime == 0{
            lastOperationTime = Date().timeIntervalSince1970
        }
    }
    func addStrokes(_ strokes:[StrokeRaw]){
        if status & Status.drawing.rawValue > 0 {
            draws[draws.count-1].strokes = draws[draws.count-1].strokes+strokes
            drawingDelegate?.getStrokes(strokes)
        }
    }
    func endDrawing(WithStroke stroke:StrokeRaw?){
        status = status & (~Status.drawing.rawValue)
        if let _stroke = stroke{
            draws[draws.count-1].strokes.append(_stroke)
        }
        savedelegate?.saveCanvas(self, completionHandler: { (success) in
            
        })
        var strokes = [StrokeRaw]()
        for draw in draws{
            for _stroke in draw.strokes{
                strokes.append(_stroke)
            }
        }
        let filename = self.name
        var operationtime = 0.0
        let currentTime = Date().timeIntervalSince1970
        operationtime = currentTime - lastOperationTime
        lastOperationTime = currentTime
        let fileName = self.name
        drawingDelegate?.drawThumbNail(from: strokes, completionHandler: { (image) in
            dispathQueueForFileOperation.async {
                if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create:true).appendingPathComponent("\(filename).png")
                {
                    do {
                        if let _image = image{
                            try _image.pngData()?.write(to: url)
                            let notification = Notification(name: NSNotification.Name(rawValue: "updateProjectInfo"), object: self, userInfo: ["fileName":fileName,"url":url,"time":operationtime])
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(notification)
                            }
                        }
                    } catch let error {
                        print("\(error)")
                    }
                    
                }
            }
        })
    }
    func startRecord(){
        status = status | Status.recording.rawValue
        drawsRecord.removeAll()
    }
    func stopRecord(){
        status = status & (~Status.recording.rawValue)
        if(self.drawsRecord.count > 0){
            let count = self.drawsRecord.count
            if(self.drawsRecord[count-1].count == 0){
                self.drawsRecord.remove(at: count-1)
            }
            else{
                savedelegate?.saveCanvas(self, completionHandler: { (success) in
                    
                })
            }
        }
    }
    
    //MARK: Play Record properties
    var drawedRecord = [StrokeRaw]()
    var recordNeedToDraw = [StrokeRaw]()
    func startPlay(){
        drawedRecord.removeAll()
        recordNeedToDraw.removeAll()
        status = Status.playing.rawValue
        var recorder = self.drawsRecord
        for draw in self.draws{
            if recorder.count > 0{
                if draw.uuid != recorder[0]{
                    drawedRecord = drawedRecord+draw.strokes
                }
                else{
                    recordNeedToDraw = recordNeedToDraw+draw.strokes
                    recorder.remove(at: 0)
                }
            }
            else{
                break
            }
        }
        let playDispatchQueue = DispatchQueue(label: "com.xiang.play")
        playDispatchQueue.async {
            [weak self] in
            var preDate = self?.recordNeedToDraw[0].created
            DispatchQueue.main.async {
                self?.drawingDelegate?.getStrokes(self?.drawedRecord ?? [])
            }
            if let recordNeedToDraw = self?.recordNeedToDraw{
                for task in recordNeedToDraw{
                    if task.created != preDate{
                        Thread.sleep(forTimeInterval: task.created-preDate! )
                    }
                    DispatchQueue.main.async {
                        self?.drawingDelegate?.getStrokes([task])
                    }
                    
                    DispatchQueue.main.async {
                        self?.drawedRecord.append(task)
                    }
                    preDate = task.created
                }
            }
            DispatchQueue.main.async {
                self?.stop()
            }
        }
    }
    func stop(){
        status = Status.idle.rawValue
        drawingDelegate?.playRecordEnd()
    }
    func redraw(_ rect:CGRect){
        if(status & Status.playing.rawValue != 0){
            drawingDelegate?.getStrokes(drawedRecord)
        }
        else{
            var strokes = [StrokeRaw]()
            for draw in draws{
                for _stroke in draw.strokes{
                    strokes.append(_stroke)
                }
            }
            drawingDelegate?.getStrokes(strokes)
        }
        
    }
}

protocol CanvasModelDelegate : class {
    func getStrokes(_ strokes:[StrokeRaw])
    func playRecordEnd()
    func drawThumbNail(from strokes:[StrokeRaw], completionHandler closure: @escaping (UIImage?)->Void)
}
