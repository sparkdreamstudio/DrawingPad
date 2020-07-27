//
//  DetailViewController.swift
//  DrawingPad
//
//  Created by xiang on 7/24/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, CanvasModelDelegate, UICanvasDelegate {
    @IBOutlet weak var canvas:UICanvas!
    @IBOutlet weak var slider:UISlider!
    @IBOutlet var collectionOfButtons: Array<UIButton>?
    @IBOutlet weak var colorIndicatorLabel:UILabel!
    @IBAction func touchUpButton(_ sender: UIButton) {
        canvasState = sender.tag
    }
    @IBAction func pickColor(_ sender:UIButton){
        for index in 0..<brushes.count{
            brushes[index].color = sender.backgroundColor!
        }
        selectBrush.color = sender.backgroundColor!
        colorIndicatorLabel.textColor = sender.backgroundColor!
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        for index in 0..<brushes.count{
            brushes[index].width = CGFloat(sender.value)
        }
        selectBrush.width = CGFloat(sender.value)
    }
    
    var canvasObject: CanvasObject? {
        didSet{
            if oldValue == nil{
                canvasObject?.drawingDelegate = self
                canvas.setNeedsDisplay()
            }
        }
    }

    private var brushes:[AbstractStroke] = [CurveStroke(),EraserStroke()]
    private var selectBrush:AbstractStroke = CurveStroke(){
        didSet{
            canvas.strokeOfBrush = selectBrush
        }
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
                var brush = brushes[0]
                brush.width = CGFloat(slider.value)
                selectBrush = brush
            case 2:
                canvas.drawable = true
                var brush = brushes[1]
                brush.width = CGFloat(slider.value)
                selectBrush = brush
            default:
                break
            }
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        canvas.canvasDelegate = self
        canvas.drawable = true
        canvasState = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }
    
    func getStrokes(_ strokes: [StrokeRaw]) {
        var nextStrokes = [AbstractStroke]()
        for strokeraw in strokes{
            if let nextStroke = getStrokeFrom(raw: strokeraw){
                nextStrokes.append(nextStroke)
            }
        }
        canvas.nextStrokes = nextStrokes
    }

    //MARK: UICanvasDelegate
       
    func drawContinuouStroke(_ stroke: AbstractStroke) {
        canvasObject?.addStrokes([stroke.getRawData()])
    }
    func drawBeganWith(stroke: AbstractStroke?) {
        canvasObject?.startDrawing()
    }
    
    func drawEndWith(stroke: AbstractStroke?) {
        
        if let _stroke = stroke{
            canvasObject?.endDrawing(WithStroke: _stroke.getRawData())
        }
        else{
            canvasObject?.endDrawing(WithStroke: nil)
        }
        
    }
    func drawStrokes(_ strokes: [AbstractStroke]) {
        //canvasObject?.add
        var strokeRaws = [StrokeRaw]()
        for stroke in strokes{
            strokeRaws.append(stroke.getRawData())
        }
        canvasObject?.addStrokes(strokeRaws)
    }
    
    func redrawOnRect(_ rect: CGRect) {
        canvasObject?.redraw(rect)
    }


}

