
//3456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_
/*:
 ## NautoLayout
 %$^&@! AutoLayout. In the time I've spent wrestling with that s**t and trying to stop it from crashing everything I could have finished my whole damn project. 
 
 Below are spit-simple set of extensions to UIView that let you accomplish simple tasks like laying out subviews uniformly along either the x or y axis, and defining the origin of any given view proportionally to its superview. It's a little more work to set up than AutoLayout, but tweaking it, revising it, and debugging it are a _lot_ less work than struggling with AutoLayout.
 
 At the end there are examples that demonstrate functionality.
 */
import UIKit
//: ### Helper extensions and =? operator
//: The =? operator:
/** Super-helpful operator that assigns an optional value to the left-hand variable only if the optional is non-nil. Compresses two lines into one (or four if you put brackets on their own line)."*/
precedencegroup DefaultPrecedence {
}
infix operator =?
public func =?<T>( lhs: inout T, rhs: T?) {
  if let rhs = rhs {
    lhs = rhs
  }
}

/** A wrapper class needed in order to make action closures Equatable. */
open class Action {
    /** `function` **must** stay as a `let` variable in order for Actions to be usefully Equatable. One Action instance must always represent one and only one immutable closure. */
    public let function: ()->Void
    public init(_ function: @escaping ()->Void) {
        self.function = function
    }
}
/** UIButton that calls its action closure when pressed. */
open class UISimpleActionButton: UIButton {
    /** The Action class wraps a closure so that its identity can be compared for Equatable purposes. */
    open var action: Action = Action{ print("action not set") }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self,
                  action: #selector(doAction),
                  for: .touchUpInside)
    }
    public convenience init(_ action: Action = Action{}, _ frame: CGRect = CGRect.zero) {
        self.init(frame: frame)
        self.action = action
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc open func doAction() { action.function() }
}

public enum LeftAndRightPlacement {
    case left
    case right
    case center
    public func applyTo(copyOf rect: CGRect, asIfIn superRect: CGRect)->CGRect {
        var newX: CGFloat
        switch self {
        case .left:
            newX = 0
        case .right:
            newX = superRect.width - rect.width
        case .center:
            newX = (superRect.width / 2) - (rect.width / 2)
        }
        return rect.copyWithNew(x: newX)
    }
    public func applyTo(_ view: UIView, inside superview: UIView) {
        view.frame = self.applyTo(copyOf: view.frame, asIfIn: superview.frame)
    }
}
public enum BasicPlacement {
    case top (LeftAndRightPlacement)
    case bottom (LeftAndRightPlacement)
    case center (LeftAndRightPlacement)
    public func applyTo(copyOf rect: CGRect, asIfIn superRect: CGRect)->CGRect {
        var leftAndRightValue: LeftAndRightPlacement
        var newY: CGFloat
        var newRect: CGRect
        switch self {
        case .top(let lar):
            leftAndRightValue = lar
            newY = 0
        case .bottom(let lar):
            leftAndRightValue = lar
            newY = superRect.height - rect.height
        case .center(let lar):
            leftAndRightValue = lar
            newY = (superRect.height / 2) - (rect.height / 2)
        }
        newRect = leftAndRightValue.applyTo(copyOf: rect, asIfIn: superRect)
        return newRect.copyWithNew(y: newY)
    }
    public func applyTo(_ view: UIView, inside superview: UIView) {
        view.frame = self.applyTo(copyOf: view.frame, asIfIn: superview.frame)
    }
}
//:Basic CGRect-related extensions:
extension CGSize {
    /** Returns this value as a CGRect with origin 0, 0.*/
    public func toRect()->CGRect {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    init (_ width: CGFloat, _ height: CGFloat) {
        self.init(width: width, height: height)
    }
}
extension CGRect {
    public var x: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }
    public var y: CGFloat {
        get { return origin.y }
        set { origin.y = newValue }
    }
    /** Creates a copy of current rect with any property changed. */
    public func copyWithNew(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil)->CGRect {
        var newFrame = self
        newFrame.x =? x
        newFrame.y =? y
        if let width = width {
            newFrame = CGRect(x: newFrame.x, y: newFrame.y, width: width, height: newFrame.height)
        }
        if let height = height {
            newFrame = CGRect(x: newFrame.x, y: newFrame.y, width: newFrame.width, height: height)
        }
        return newFrame
    }
    /** Returns a copy with origin set to 0, 0. */
    public func copyAtZeroZero()->CGRect {
        return copyWithNew(x: 0, y:0)
    }
    
    //*** Vertical layout functions.
    /** Takes the given rects and returns them stacked vertically inside this rect, with their centers aligned at the given x value. Keeps a consistent gap between each rect and, by default, the same gap as a margin at either end. If a custom margin is set, the rects will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutVertically(subRects rects: [CGRect], centerX: CGFloat, margin: CGFloat? = nil)->[CGRect] {
        //find this rect's height less margin
        var operativeHeight = height
        if let margin = margin {
            operativeHeight -= (margin * 2)
        }
        //find that less total height of given rects
        var rectsHeight: CGFloat = 0
        rects.forEach({ rectsHeight += $0.height })
        let availablePadding = operativeHeight - rectsHeight
        //find amount to put between each rect
        let spaceBetween: CGFloat
        let spacesNeeded: Int
        if let _ = margin {
            spacesNeeded = rects.count - 1
        } else {
            spacesNeeded = rects.count + 1
        }
        spaceBetween = availablePadding / CGFloat(spacesNeeded)
        //set a starting y
        var currentY: CGFloat = spaceBetween
        if let margin = margin {
            currentY = margin
        }
        //calculate the new rects
        var newRects: [CGRect] = []
        for var rect in rects {
            // set the origin of the current rect
            rect.x = centerX - (rect.width / 2)
            rect.y = currentY
            currentY += rect.height + spaceBetween
            newRects.append(rect)
        }
        return newRects
    }
    /** Functions exactly as layoutVertically, but with the center x value specified between 0 and 1, reflecting the percentage of this rect's width along which the centers of the subRects should align. */
    public func layoutVertically(subRects rects: [CGRect], proportionalCenterX: CGFloat, margin: CGFloat? = nil)->[CGRect] {
        let calculatedX = width * proportionalCenterX
        return self.layoutVertically(subRects: rects, centerX: calculatedX, margin: margin)
    }
    /** Takes the given rects and returns them stacked vertically inside this rect, with their centers aligned at this rect's center x value. Keeps a consistent gap between each rect and, by default, the same gap as a margin at either end. If a custom margin is set, the rects will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutVerticallyAlongCenterX(subRects rects: [CGRect], margin: CGFloat? = nil)-> [CGRect] {
        return self.layoutVertically(subRects: rects, proportionalCenterX: 0.5, margin: margin)
    }
    
    //*** Horizontal layout functions.
    /** Takes the given rects and returns them lined up horizontally inside this rect, with their centers set at the given y value. Keeps a consistent gap between each rect and, by default, the same gap as a margin at either end. If a custom margin is set, the rects will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutHorizontally(subRects rects: [CGRect], centerY: CGFloat, margin: CGFloat? = nil)->[CGRect] {
        //find this rect's width less margin
        var operativeWidth = width
        if let margin = margin {
            operativeWidth -= (margin * 2)
        }
        //find that less total width of given rects
        var rectsWidth: CGFloat = 0
        rects.forEach({ rectsWidth += $0.width })
        let availablePadding = operativeWidth - rectsWidth
        //find amount to put between each rect
        let spaceBetween: CGFloat
        let spacesNeeded: Int
        if let _ = margin {
            spacesNeeded = rects.count - 1
        } else {
            spacesNeeded = rects.count + 1
        }
        spaceBetween = availablePadding / CGFloat(spacesNeeded)
        //set a starting x
        var currentX: CGFloat = spaceBetween
        if let margin = margin {
            currentX = margin
        }
        //calculate the new rects
        var newRects: [CGRect] = []
        for var rect in rects {
            // set the origin of the current rect
            rect.y = centerY - (rect.height / 2)
            rect.x = currentX
            currentX += rect.width + spaceBetween
            newRects.append(rect)
        }
        return newRects
    }
    /** Functions exactly as layoutHorizontally, but with the center y value specified between 0 and 1, reflecting the percentage of this rect's height along which the centers of the subRects should align. */
    public func layoutHorizontally(subRects rects: [CGRect], proportionalCenterY: CGFloat, margin: CGFloat? = nil)->[CGRect] {
        let calculatedY = height * proportionalCenterY
        return self.layoutHorizontally(subRects: rects, centerY: calculatedY, margin: margin)
    }
    /** Takes the given rects and returns them lined up horizontally inside this view, with their centers aligned at this view's center y value. Keeps a consistent gap between each view and, by default, the same gap as a margin at either end. If a custom margin is set, the views will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutHorizontallyAlongCenterY(subRects rects: [CGRect], margin: CGFloat? = nil)-> [CGRect] {
        return self.layoutHorizontally(subRects: rects, proportionalCenterY: 0.5, margin: margin)
    }
}

//:UIView extensions:
/** Retrieves an array of frames from an array of `UIView`s */
public extension Array where Element: UIView {
    public func frames()->[CGRect] {
        return map{ $0.frame }
    }
}
public extension UIView {
    /** Convenience init for creating a view without creating a frame first. Can optionally specify a background color as well.*/
    public convenience init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor = .yellow) {
        self.init(frame: CGRect(x: x, y: y, width: width, height: height))
        self.backgroundColor = color
    }
    
    /** Convenience init for making a view with default origin of 0, 0. Can also specify a background color. Default color is yellow.*/
    public convenience init(width: CGFloat, height: CGFloat, color: UIColor = .yellow) {
        /* background color defaults to yellow */
        let zeroedFrame = CGRect(x: 0, y: 0, width: width, height: height)
        self.init(frame: zeroedFrame)
        backgroundColor = color
    }
    /** Convenience init for making a view with default origin of 0, 0. Can also specify a background color. Default color is yellow. */
    public convenience init(size: CGSize, color: UIColor = .yellow) {
        /* background color defaults to yellow */
        self.init(width: size.width, height: size.height, color: color)
    }
    public var width: CGFloat {
        get { return frame.width }
        set {
            let old = self.frame
            adjustFrame(x: old.origin.x, y: old.origin.y,
                        width: newValue, height: old.height)
        }
    }
    public var height: CGFloat {
        get { return frame.height }
        set {
            let old = self.frame
            adjustFrame(x: old.origin.x, y: old.origin.y,
                        width: old.width, height: newValue)
        }
    }
    public var x: CGFloat {
        get { return frame.origin.x }
        set {
            let old = self.frame
            adjustFrame(x: newValue, y: old.origin.y,
                        width: old.width, height: old.height)
        }
    }
    public var y: CGFloat {
        get { return frame.origin.y }
        set {
            let old = self.frame
            adjustFrame(x: old.origin.x, y: newValue,
                        width: old.width, height: old.height)
        }
    }
    public var origin: CGPoint {
        get { return frame.origin }
        set {
            let old = self.frame
            adjustFrame(x: newValue.x, y: newValue.y,
                        width: old.width, height: old.height)
        }
    }
    /** Convenience method allowing any property of the frame to be set directly. */
    public func adjustFrame(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.frame = frame.copyWithNew(x: x, y: y, width: width, height: height)
    }
    /** Proportional placement function, stating proportions as between 0 & 1 */
    public func setOriginProportionallyForSubview(_ view: UIView, x: CGFloat? = nil, y: CGFloat? = nil){
        if !self.subviews.contains(view) {
            self.addSubview(view)
        }
        if let x = x {
            let absoluteX = self.frame.width * x
            view.frame.origin.x = absoluteX
        }
        if let y = y {
            let absoluteY = self.frame.width * y
            view.frame.origin.y = absoluteY
        }
    }
    /** Convenience function for removing all subviews. */
    func removeAllSubviews() {
        subviews.forEach({ $0.removeFromSuperview() })
    }
    /** Changes the superview of a given view without changing its absolute position on screen.*/
    func move(from superview: UIView, to otherView: UIView){
        origin = superview.convert(origin, to: otherView)
        otherView.addSubview(self)
    }
}

//: ### Nautolayout extensions:
extension UIView {
    /** Simple way to position subview at the same time as adding it to superview.*/
    public func put(_ thisView: UIView, in location: BasicPlacement) {
        /* simple relative positioning of view at time of adding it */
        if subviews.contains(thisView) ==  false {
            addSubview(thisView)
        }
        location.applyTo(thisView, inside: self)
    }
    //*** Vertical layout functions.
    /** Takes the given views and returns them stacked vertically inside this view, with their centers aligned at the given x value. Keeps a consistent gap between each view and, by default, the same gap as a margin at either end. If a custom margin is set, the views will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutVertically(_ views:[UIView], centerX: CGFloat, margin: CGFloat? = nil) {
        //Get the subframes laid out correctly
        let newFrames = frame.layoutVertically(subRects: views.frames(), centerX: centerX, margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }  /** Functions exactly as layoutVertically, but with the center x value specified between 0 and 1, reflecting the percentage of this view's width along which the centers of the subViews should align. */
    public func layoutVertically(_ views: [UIView], proportionalCenterX: CGFloat, margin: CGFloat? = nil) {
        //Get the subframes laid out correctly
        let newFrames = frame.layoutVertically(subRects: views.frames(), proportionalCenterX: proportionalCenterX, margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }
    
    /** Takes the given views and returns them stacked vertically inside this view, with their centers aligned at this view's center x value. Keeps a consistent gap between each view and, by default, the same gap as a margin at either end. If a custom margin is set, the views will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutVerticallyAlongCenterX(_ views:[UIView],  margin: CGFloat? = nil) {
        /* lays out given views at center of self */
        //Get the subframes laid out correctly
        let newFrames = frame.layoutVerticallyAlongCenterX(subRects: views.frames(), margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }
    
    //*** Horizontal layout functions.
    /** Takes the given views and returns them lined up horizontally inside this view, with their centers set at the given y value. Keeps a consistent gap between each view and, by default, the same gap as a margin at either end. If a custom margin is set, the views will keep a consistent gap between each other but hew to the specified margin.*/
    public func layoutHorizontally(_ views: [UIView], centerY: CGFloat, margin: CGFloat? = nil) {
        //Get the subframes laid out correctly
        let newFrames = frame.layoutHorizontally(subRects: views.frames(), centerY: centerY, margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }
    /** Functions exactly as layoutHorizontally, but with the center y value specified between 0 and 1, reflecting the percentage of this view's height along which the centers of the subviews should align. */
    public func layoutHorizontally(_ views: [UIView], proportionalCenterY: CGFloat, margin: CGFloat? = nil) {
        //Get the subframes laid out correctly
        let newFrames = frame.layoutHorizontally(subRects: views.frames(), proportionalCenterY: proportionalCenterY, margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }
    /** Takes the given views and returns them lined up horizontally inside this view, with their centers aligned at this view's center y value. Keeps a consistent gap between each view and, by default, the same gap as a margin at either end. If a custom margin is set, the views will keep a consistent gap between each other but hew to the specified margin. */
    public func layoutHorizontallyAlongCenterY(_ views: [UIView], margin: CGFloat? = nil) {
        //Get the subframes laid out correctly
        let newFrames = frame.layoutHorizontallyAlongCenterY(subRects: views.frames(), margin: margin)
        //Apply the subframes
        views.enumerated().forEach({
            $0.element.frame = newFrames[$0.offset]
            //Make sure the given view is a subview
            if subviews.contains($0.element) == false {
                addSubview($0.element)
            }
        })
    }
}

/** View specification protocol. Can be used to create a UIView that has the given specs.*/
public protocol ViewSpecificationProtocol {
    var frame: CGRect? { get set }
    var backgroundColor: UIColor? { get set }
    var contentMode: UIView.ContentMode? { get set }
    var clipsToBounds: Bool? { get set }
    var cornerRadius: CGFloat? { get set }
    var blurStyle: UIBlurEffect.Style? { get set }
    var text: String? { get set }
    var textColor: UIColor? { get set }
    var fontSize: CGFloat? { get set }
    var imageName: String? { get set }
    var action: Action? { get set }
    /** Specifies this view's placement in its superview. Overrides any origin specified by frame property.*/
    var basicPlacement: BasicPlacement? { get set }
    var subviewSpecs: [ViewSpecificationProtocol]? { get set }
    func build()->UIView
}
/** ViewSpecificationProtocol extension that creates a UIView.*/
extension ViewSpecificationProtocol {
    /** Build a view from the spec. Only defined parameters are applied. Extensive notes in QuickHelp.
     - note:
     - Always returns a UIView, but if *text* is defined, it is actually a UILabel, and if *imageName* is defined, it's a UIImageView. If both text and imageName are defined, it's a UIImageView with a UILabel subview.
     - If both *text* and *imageName* are defined, it returns a UIView that has a UILabel and UIImageView as subviews, placed in a default arrangement:
     - centered horizontally
     - stacked vertically
     - image on top.
     - If *action* is defined, a UISimpleActionButton is placed as a subview of the main view, covering the total area of the view. When the view is pressed, this action is executed.
     - For more precise layout control, define each element as its own ViewSpec in *subviewSpecs.*
     - If *frame* is undefined, a default frame of `(0, 0, 200, 200)` is used.
     - A *basicPlacement* setting always overrides any origin specifed by *frame.*
     - By default *clipsToBounds* is set to `true.`
     - Labels are automatically inset by `0.05 * frame.width`, to prevent the text from coming flush with the view.
     */
    public func build()->UIView {
        //Copy self to avoid needing a mutating func.
        var values = self
        //Declare a UIView and define its frame.
        var mainView = UIView()
        if let frm = values.frame {
            mainView.frame = frm
        } else {
            mainView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        }
        //Declare optional values for a label and an image.
        var label: UILabel?
        var imageView: UIImageView?
        //If text is set, make the label = UILabel with it.
        if let text = values.text {
            label = UILabel()
            label!.textAlignment = .center
            if let txColor = textColor {
                label!.textColor = txColor
            }
            if let fsize = fontSize {
                label!.font = label!.font.withSize(fsize)
            }
            label!.contentMode =? contentMode
            label!.numberOfLines = 0
            
            let inset = mainView.frame.width * 0.05
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.firstLineHeadIndent = inset
            paragraphStyle.headIndent = inset
            paragraphStyle.tailIndent = mainView.frame.width - inset
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let fullRange = NSRange.init(location: 0, length: text.count)
            let attributedText = NSMutableAttributedString.init(string: text)
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: fullRange)
            
            label!.attributedText = attributedText
        }
        //If imageName is set, check if there's an image by that name.
        if let imageName = imageName {
            //If there is an image by that name, create a UIView from it and use the image's size as a default frame.
            if let image = UIImage(named: imageName) {
                imageView = UIImageView(frame: image.size.toRect())
                imageView?.image = image
                imageView!.contentMode =? contentMode
                imageView!.backgroundColor = .clear
            }
        }
        //If both a label and an imageView have been made, make them subviews with default positioning: centered horizontally and stacked vertically, image on top.
        if label != nil && imageView != nil {
            //Give the image most of the frame height.
            let imageHeight = frame!.height / 5 * 3.85
            imageView?.frame = CGRect(x: 0, y: 0, width: frame!.width, height: imageHeight)
            //Give the label the rest.
            let labelHeight = frame!.height - imageHeight
            label?.frame = CGRect(x: 0, y: imageHeight, width: frame!.width, height: labelHeight)
            mainView.layoutVerticallyAlongCenterX([imageView!, label!])
        } else {
            //If either label or imageView is non-nil, assign it to step in as mainView.
            mainView =? label
            mainView =? imageView
        }
        //Apply the values that can exist on every UIView.
        mainView.frame =? values.frame
        mainView.backgroundColor =? values.backgroundColor
        mainView.contentMode =? contentMode
        //Create the subviews.
        if let subs = values.subviewSpecs {
            subs.forEach({
                let subCopy = $0
                let newSubview = subCopy.build()
                mainView.addSubview(newSubview)
                //Override the frame placement if a basicPlacement is defined.
                if let placement = $0.basicPlacement {
                    mainView.put(newSubview, in: placement)
                }
            })
        }
        //Add a blur effect behind everything, if defined.
        if let bStyle = blurStyle {
            let existingMain = mainView
            existingMain.backgroundColor = .clear
            mainView = UIVisualEffectView(effect: UIBlurEffect(style: bStyle))
            mainView.frame = existingMain.frame
            existingMain.frame = existingMain.frame.copyAtZeroZero()
            (mainView as! UIVisualEffectView).contentView.addSubview(existingMain)
        }
        //Round corners, if defined.
        if let cr = values.cornerRadius {
            mainView.layer.cornerRadius = cr
        }
        //Set clipsToBounds, if defined. Otherwise default to true.
        if let ctb = values.clipsToBounds {
            mainView.clipsToBounds = ctb
        } else {
            mainView.clipsToBounds = true
        }
        //Add a button, if defined, covering the full view, and calling `action` when tapped.
        if let action = action {
            let button = UISimpleActionButton(frame: mainView.frame.copyAtZeroZero())
            button.action = action
            mainView.addSubview(button)
            mainView.isUserInteractionEnabled = true
        }
        //Return the modified view.
        return mainView
    }
}
/** Standard ViewSpecificationProtocol implementation. The order of parameters is:
 - frame: CGRect?
 - backgroundColor: UIColor?
 - contentMode: UIViewContentMode?
 - clipsToBounds: Bool?
 - cornerRadius: CGFloat?
 - blurStyle: UIBlurEffectStyle?
 - text: String?
 - textColor: UIColor?
 - fontSize: CGFloat?
 - imageName: String?
 - action: Action?
 - basicPlacement: BasicPlacement?
 - subviewSpecs: [ViewSpecificationProtocol]?
 
 */
public struct ViewSpec: ViewSpecificationProtocol {
    public var frame: CGRect?
    public var backgroundColor: UIColor?
    public var contentMode: UIView.ContentMode?
    public var clipsToBounds: Bool?
    public var cornerRadius: CGFloat?
    public var blurStyle: UIBlurEffect.Style?
    public var text: String?
    public var textColor: UIColor?
    public var fontSize: CGFloat?
    public var imageName: String?
    public var action: Action?
    public var basicPlacement: BasicPlacement?
    public var subviewSpecs: [ViewSpecificationProtocol]?
    public init(frame: CGRect? = nil,
                backgroundColor: UIColor? = nil,
                contentMode: UIView.ContentMode? = nil,
                clipsToBounds: Bool? = nil,
                cornerRadius: CGFloat? = nil,
                blurStyle: UIBlurEffect.Style? = nil,
                text: String? = nil,
                textColor: UIColor? = nil,
                fontSize: CGFloat? = nil,
                imageName: String? = nil,
                action: Action? = nil,
                basicPlacement: BasicPlacement? = nil,
                subviewSpecs: [ViewSpecificationProtocol]? = nil) {
        self.frame =? frame
        self.backgroundColor =? backgroundColor
        self.contentMode =? contentMode
        self.clipsToBounds =? clipsToBounds
        self.cornerRadius =? cornerRadius
        self.blurStyle =? blurStyle
        self.text =? text
        self.textColor =? textColor
        self.fontSize =? fontSize
        self.imageName =? imageName
        self.action =? action
        self.basicPlacement = basicPlacement
        self.subviewSpecs =? subviewSpecs
    }
}


let RECTANGLE = CGSize(100, 65)
let SQUARE = CGSize(50, 50)
let YELLOW = UIColor.yellow
let ORANGE = UIColor.orange
let SUPERVIEW = UIView(size: CGSize(275, 400), color: ORANGE)

var rectViews = (1...3).map({ _ in UIView(size: SQUARE, color: YELLOW) })
rectViews.append(UIView(size: RECTANGLE, color: YELLOW))

//: ### Examples
//:Can layout given views at any x value of superview.
SUPERVIEW.layoutVertically(rectViews, centerX: 60)
//: Can also layout using a value between 0 and 1 to calculate a proportional x value.
SUPERVIEW.layoutVertically(rectViews, proportionalCenterX: 0.8)
//: A convenience method allows automatically laying out views at center x.
SUPERVIEW.layoutVerticallyAlongCenterX(rectViews)
//: The same can be done horizontally, at any y value of superview.
SUPERVIEW.layoutHorizontally(rectViews, centerY: 330)
//: Can also layout using a value between 0 and 1 to calculate a proportional y value.
SUPERVIEW.layoutHorizontally(rectViews, proportionalCenterY: 0.2)
//: And again, a convenience method allows automatic vertical centering.
SUPERVIEW.layoutHorizontallyAlongCenterY(rectViews)
//: You can place views as proportions of their superview, using values between 0 and 1.
SUPERVIEW.removeAllSubviews()
let rectView = UIView(size: RECTANGLE)
SUPERVIEW.setOriginProportionallyForSubview(rectView, x: 0.1, y: 0.1)
//: And you can modify a single axis proportionally too.
SUPERVIEW.setOriginProportionallyForSubview(rectView, x: 0.6)
SUPERVIEW.setOriginProportionallyForSubview(rectView, y: 0.8)
//: In either axis you can specify a desired margin, and the subviews will space themselves evenly across the leftover space.
SUPERVIEW.removeAllSubviews()
SUPERVIEW.layoutVerticallyAlongCenterX(rectViews, margin: 70)
//: Via the same functionality you can specify a margin of 0 to make the views hug the edges of the superview.
SUPERVIEW.layoutVerticallyAlongCenterX(rectViews, margin: 0)
//: Setting large enough margins will make the views overlap.
SUPERVIEW.layoutHorizontallyAlongCenterY(rectViews, margin: 70)
//: That's it! It's primitive, but it can do a lot of what the StackView can do, and it will never confound you until you're pulling your hair out and screaming with rage. And that's worth something in this fallen world!
