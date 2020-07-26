//
//  DetailViewController.swift
//  DrawingPad
//
//  Created by xiang on 7/24/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var canvas:UICanvas!

    @IBOutlet var collectionOfButtons: Array<UIButton>?
    @IBAction func touchUpButton(_ sender: UIButton) {
        canvasState = sender.tag
    }
    
    private var canvasState = 0{
        didSet{
            if let buttons = collectionOfButtons{
                for button in buttons{
                    button.isSelected = button.tag == canvasState
                }
            }
            switch canvasState {
            case 0:
                canvas.drawable = false
            case 1:
                canvas.drawable = true
            case 2:
                canvas.drawable = true
            default:
                break
            }
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
        canvas.drawable = true
        canvasState = 0
    }

    var detailItem: NSDate? {
        didSet {
            // Update the view.
            configureView()
        }
    }


}

