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

