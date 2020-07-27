//
//  LocalManager.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import UIKit

extension ProjectsManager{
    private static let manager : ProjectsManager = ProjectsManager()
    static func getLocalProjectManager() -> ProjectsManager{
        if manager.canvasdelegate == nil{
            manager.canvasdelegate = LocalCanvasRawDataAccess()
        }
        if manager.projectdelegate == nil{
            manager.projectdelegate = ProjectsLocalAccess()
        }
        return manager
    }
}


fileprivate class ProjectsLocalAccess:ProjectsControlProtocol{
    func loadModel(completionHandler closure: @escaping (Bool, [CanvasBrife]?) -> Void) {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("projectsList.json"){
            dispathQueueForFileOperation.async {
                do {
                    let data = try Data(contentsOf: url)
                    let brifes = try JSONDecoder().decode([CanvasBrife].self, from: data)
                    DispatchQueue.main.async {
                        closure(true,brifes)
                    }
                } catch let error {
                    print("load projects failed: \(error)")
                    DispatchQueue.main.async {
                        closure(false,nil)
                    }
                }
            }
        }
    }
    
    func saveModel(_ model: [CanvasBrife], closure: @escaping (Bool) -> Void) {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("projectsList.json"){
            dispathQueueForFileOperation.async {
                do {
                    try JSONEncoder().encode(model).write(to: url)
                    DispatchQueue.main.async {
                        closure(true)
                    }
                } catch let error {
                    print("save projects failed: \(error)")
                    DispatchQueue.main.async {
                        closure(false)
                    }
                }
            }
        }
    }
}

fileprivate class LocalCanvasRawDataAccess: ModifyCanvasModelProtocol,LoadAndDeleteCanvasModelProtocol{
    
    func loadCanvas(WithName name: String, completionHandler closure: @escaping (Bool, CanvasObject?) -> Void) {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name).json")
        {
            dispathQueueForFileOperation.async {
                do {
                    let data = try Data(contentsOf: url)
                    let canvasRaw = try JSONDecoder().decode(CanvasRawData.self, from: data)
                    var canvas = CanvasObject(withName: name, andRawData: canvasRaw)
                    canvas.savedelegate = self
                    DispatchQueue.main.async {
                        closure(true,canvas)
                    }
                } catch let error{
                    print("load canvas failed: \(error)")
                    DispatchQueue.main.async {
                        closure(false,nil)
                    }
                }
            
            }
        }
    }
    
    func saveCanvas(_ canvas: CanvasObject, completionHandler closure: @escaping (Bool) -> Void) {
        let rawData = canvas.exportRawData()
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
    
    func deleteCanvas(_ canvasName:String, completionHandler closure: @escaping (Bool) -> Void) {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(canvasName).json"){
            do {
                try FileManager.default.removeItem(at: url)
                DispatchQueue.main.async {
                    closure(true)
                }
            } catch let error {
                print("delete canvas failed: \(error)")
                DispatchQueue.main.async {
                    closure(false)
                }
            }
            
        }
    }
    
}
