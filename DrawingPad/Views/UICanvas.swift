//
//  UICanvas.swift
//  DrawingPad
//
//  Created by xiang on 7/25/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit


protocol UICanvasDelegate : class {
    func drawBeganWith(stroke:AbstractStroke?)
    func drawEndWith(stroke:AbstractStroke?)
    func drawStrokes(_ strokes:[AbstractStroke])
    func drawContinuouStroke(_ stroke:AbstractStroke)
    func redrawOnRect(_ rect:CGRect)
}

class UICanvas: UIView {
    /*struct Stroke{
        var points:[CGPoint]
        var strokeColor:CGColor = UIColor.black.cgColor
        var strokeWidth:CGFloat = 1
    }*/
    // MARK: canvas properties
    private var drawing:Bool = false
    private var buffer:UIImage? {
        didSet{
            if let image = self.buffer{
                visibleCanvas.image = image
            }
        }
    }
    var nextStrokes:[AbstractStroke]? {
        didSet{
            if self.nextStrokes != nil {
                self.drawStrokesToVisibleImage()
            }
        }
    }
    var canvasSize:CGSize = CGSize.zero {
        didSet{
            scrollView.contentSize = canvasSize
        }
    }
    var drawable:Bool = true{
        didSet{
            scrollView.isScrollEnabled = !self.drawable
            visibleCanvas.isUserInteractionEnabled = self.drawable
        }
    }
    var strokeOfBrush:AbstractStroke?
    private var strokeForGesture:AbstractStroke?
    
    
    // MARK: view properties

    weak var canvasDelegate:UICanvasDelegate?
    private let visibleCanvas:UIImageView = UIImageView()
    private let scrollView:UIScrollView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureView()
    }
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    // MARK: other properties
    private static var drawImageQueueName = "com.xiang.drawImage"
    private let drawImageQueue = DispatchQueue(label:drawImageQueueName)
    func configureView(){
        self.backgroundColor = .white
        self.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
        scrollView.delegate = self
        scrollView.addSubview(visibleCanvas)
        canvasSize = CGSize(width: 2000,height: 2000)
        visibleCanvas.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        visibleCanvas.frame = CGRect(origin: scrollView.contentOffset, size: self.scrollView.bounds.size)
        self.redrawCanvas(inRect: visibleCanvas.frame)
    }
    //private var middlePoint:CGPoint?
    //private var touchMoveMemory:[CGPoint] = [CGPoint](repeating: CGPoint(), count: 5)
    //private var touchMoveCount = 0;
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let offset = scrollView.contentOffset
        if(gesture.state == .began){
            drawing = true
            canvasDelegate?.drawBeganWith(stroke: nil)
            let point = gesture.location(in: visibleCanvas).getPointAddOffset(offset)
            strokeForGesture = strokeOfBrush
            strokeForGesture?.created = Date()
            strokeForGesture?.addPoint(point)
            //touchMoveMemory[touchMoveCount] = gesture.location(in: visibleCanvas)
        }
        else if(gesture.state == .changed){
            let point = gesture.location(in: visibleCanvas).getPointAddOffset(offset)
            strokeForGesture?.addPoint(point)
            if let _drawingStroke = strokeForGesture{
                if _drawingStroke.isCompleted() && _drawingStroke.isConinuous(){
                    canvasDelegate?.drawContinuouStroke(_drawingStroke)
                }
            }
        }
        else {
            drawing = false
            //touchMoveCount = 0
            if strokeForGesture?.isConinuous() == false{
                canvasDelegate?.drawEndWith(stroke: strokeForGesture)
            }
            else{
                canvasDelegate?.drawEndWith(stroke: nil)
            }
            
        }
    }
    private func redrawCanvas(inRect rect:CGRect){
        canvasDelegate?.redrawOnRect(rect)
        self.buffer = nil
        self.drawImageQueue.async {
            DispatchQueue.main.async {
                
                
            }
        }
    }
    private func drawStrokesToVisibleImage(){
        let rect = self.visibleCanvas.bounds
        let strokes = nextStrokes
        let origin = self.scrollView.contentOffset
        drawImageQueue.async { [weak self] in
            UIGraphicsBeginImageContext(rect.size)
            let context = UIGraphicsGetCurrentContext()
            UIColor.clear.setFill()
            UIRectFill(rect)
            context?.setLineCap(.round)
            if let _image = self?.buffer{
                _image.draw(in: rect)
            }
            if let _strokes = strokes{
                for stroke in _strokes{
                    stroke.drawRelativeOrigin(origin, onContext: context)
                }
            }
            
            let tempImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if strokes?.count == 1 && strokes?[0].isConinuous()==false && self?.drawing == true{
                DispatchQueue.main.async {
                    self?.visibleCanvas.image = tempImage
                }
            }
            else{
                DispatchQueue.main.async {
                    self?.buffer = tempImage
                }
            }
            
        }
    }
    
    static private func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
    }
    
    
}

extension UICanvas:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let newFrame = CGRect(origin: scrollView.contentOffset, size: self.scrollView.bounds.size)
        visibleCanvas.frame = newFrame
        self.redrawCanvas(inRect: newFrame)
    }
}

extension CGPoint{
    func getPointAddOffset(_ offset:CGPoint) -> CGPoint{
        return CGPoint(x: x + offset.x, y: y + offset.y)
    }
}
