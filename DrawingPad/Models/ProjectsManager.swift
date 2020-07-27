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
    var workingDuration:Double = 0
}

class ProjectsManager{
    private var brifes:[CanvasBrife]=[CanvasBrife]()
    var projectdelegate:ProjectsControlProtocol?
    var canvasdelegate: (LoadAndDeleteCanvasModelProtocol & ModifyCanvasModelProtocol)?
    
    subscript(index:Int) -> CanvasBrife?{
        get{
            if index >= count
            {
                return nil
            }
            return brifes[index]
        }
        set(newValue){
            if let _newValue = newValue, index < count{
                brifes[index] = _newValue
            }
        }
        
    }
    var count:Int {
        return brifes.count
    }
    
    func addCanvas(modelSaveFinishedHandler closureModel:@escaping (Bool)->Void, canvasSaveFinishedHandler closureCanvas:@escaping (Bool, CanvasObject?)->Void){
        let canvasObject = CanvasObject()
        canvasObject.savedelegate = canvasdelegate
        let brife = CanvasBrife(unique_name: canvasObject.name)
        brifes.append(brife)
        projectdelegate?.saveModel(brifes, closure: {[weak self] (success) in
            DispatchQueue.main.async {
                closureModel(success)
                self?.canvasdelegate?.saveCanvas(canvasObject, completionHandler: { (success) in
                    DispatchQueue.main.async {
                        closureCanvas(success, success == true ? canvasObject : nil)
                        
                    }
                })
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
                                if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true){
                                    dispathQueueForFileOperation.async {
                                        try? FileManager.default.removeItem(at: url)
                                    }
                                }
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
                let localcanvas = canvas
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


