//
//  ProjectManagerProtocol.swift
//  DrawingPad
//
//  Created by xiang on 7/26/20.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation

protocol ProjectsControlProtocol : class {
    func loadModel(completionHandler closure: @escaping (Bool,[CanvasBrife]?) -> Void)
    func saveModel(_ model:[CanvasBrife], closure: @escaping (Bool) -> Void)
}
