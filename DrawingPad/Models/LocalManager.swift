//
//  LocalManager.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit

class LoadCanvasRawDataLoader: SaveCanvasModelProtocol,LoadCanvasModelProtocol{
    struct CanvasRawData: Codable{
        var draws:[CanvasObject.ContinousDrawing]
        var drawsRecord : [[String]]
        var height:CGFloat
        var width:CGFloat
        var json: Data? {
            return try? JSONEncoder().encode(self)
        }
    }
    func saveCanvas(_ canvas: CanvasObject, completionHandler closure: @escaping (Bool) -> Void) {
        let rawData = CanvasRawData(draws: canvas.draws, drawsRecord: canvas.drawsRecord, height: canvas.size.height, width: canvas.size.width)
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(canvas.name).json"){
            dispathQueueForFileOperation.async {
                do {
                    try rawData.json?.write(to: url)
                    DispatchQueue.main.async {
                        closure(true)
                    }
                } catch let error {
                    print("save canvas failed: \(error)")
                    DispatchQueue.main.async {
                        closure(false)
                    }
                }
            }
            
        }
    }
    
    func loadCanvas(WithName name: String, completionHandler closure: @escaping (Bool, CanvasObject?) -> Void) {
        
    }
}
