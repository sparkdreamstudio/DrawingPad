//
//  UICanvas.swift
//  DrawingPad
//
//  Created by xiang on 7/25/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

struct Paint {
    fileprivate struct Stroke{
        /*var previousPoint:CGPoint
        var middlePoint:CGPoint
        var lastPoint:CGPoint*/
        var points:[CGPoint]
        var strokeColor:CGColor = UIColor.black.cgColor
        var strokeWidth:CGFloat = 1
    }
    private var strokeLines:[Stroke] = [Stroke]()
    mutating fileprivate func addStrokes(_ strokes:[Stroke]){
        strokeLines = strokeLines + strokes
    }
    
    fileprivate static func getVisibleStrokes(in rect:CGRect, fromPaint paint:Paint) -> [Paint.Stroke]{
        return paint.strokeLines
    }
}
struct Brush{
    var color:UIColor = .black
    var width:CGFloat = 10
}
class UICanvas: UIView {
    // MARK: canvas properties
    var brush = Brush()
    private var paint:Paint = Paint()
    private var buffer:UIImage? {
        didSet{
            if let image = self.buffer{
                visibleCanvas.image = image
            }
        }
    }
    private var nextStrokes:[Paint.Stroke]? {
        didSet{
            if self.nextStrokes != nil {
                self.drawStrokesToVisibleImage()
            }
        }
    }
    open var canvasSize:CGSize = CGSize.zero {
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
    
    
    // MARK: view properties
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
    private var middlePoint:CGPoint?
    private var touchMoveMemory:[CGPoint] = [CGPoint](repeating: CGPoint(), count: 5)
    private var touchMoveCount = 0;
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if(gesture.state == .began){
            touchMoveCount = 0
            touchMoveMemory[touchMoveCount] = gesture.location(in: visibleCanvas)
        }
        else if(gesture.state == .changed){
            let point = gesture.location(in: visibleCanvas)
            touchMoveCount+=1
            touchMoveMemory[touchMoveCount] = point
            if(touchMoveCount==4){
                let offset = scrollView.contentOffset
                touchMoveMemory[3]=CGPoint(x: (touchMoveMemory[2].x + touchMoveMemory[4].x)/2,
                                           y: (touchMoveMemory[2].y + touchMoveMemory[4].y)/2)
                var points = [CGPoint]()
                for index in 0...3{
                    let p = touchMoveMemory[index]
                    points.append(CGPoint(x: p.x+offset.x, y: p.y+offset.y))
                }
                let stroke = Paint.Stroke(points: points, strokeColor: brush.color.cgColor, strokeWidth: brush.width)
                touchMoveMemory[0] = touchMoveMemory[3];
                touchMoveMemory[1] = touchMoveMemory[4];
                touchMoveCount = 1;
                self.paint.addStrokes([stroke])
                self.nextStrokes = [stroke]
                
            }
            /*let currentGestPosition = gesture.location(in: visibleCanvas)
            let offset = scrollView.contentOffset
            let stroke = Paint.Stroke(previousPoint: CGPoint(x: firstPoint!.x+offset.x, y: firstPoint!.y+offset.y),
                middlePoint: CGPoint(x: middlePoint!.x+offset.x, y: middlePoint!.y+offset.y),
                lastPoint: CGPoint(x: currentGestPosition.x+offset.x, y: currentGestPosition.y+offset.y), strokeColor: brush.color.cgColor, strokeWidth: brush.width)
            firstPoint = middlePoint
            middlePoint = currentGestPosition
            self.paint.addStrokes([stroke])
            self.nextStrokes = [stroke]*/
        }
        else {
            touchMoveCount = 0
        }
    }
    private func redrawCanvas(inRect rect:CGRect){
        let _paint = self.paint
        self.drawImageQueue.async {
            let strokesToDraw = Paint.getVisibleStrokes(in: rect, fromPaint: _paint)
            DispatchQueue.main.async {
                self.buffer = nil
                self.nextStrokes = strokesToDraw
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
                    context?.setLineWidth(stroke.strokeWidth)
                    context?.setStrokeColor(stroke.strokeColor)
                    if(stroke.strokeColor == UIColor.clear.cgColor){
                        context?.setBlendMode(.clear)
                    }
                    context?.move(to: CGPoint(x: stroke.points[0].x-origin.x,
                                              y: stroke.points[0].y-origin.y))
                    context?.addCurve(to: CGPoint(x: stroke.points[3].x-origin.x,
                                                  y: stroke.points[3].y-origin.y),
                                      control1: CGPoint(x: stroke.points[1].x-origin.x,
                                                        y: stroke.points[1].y-origin.y),
                                      control2: CGPoint(x: stroke.points[2].x-origin.x,
                                                        y: stroke.points[2].y-origin.y))
                    context?.strokePath()
                }
            }
            let tempImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                self?.buffer = tempImage
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
