
//3456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_
/*:
 ## NautoLayout
 %$^&@! AutoLayout. In the time I've spent wrestling with that s**t and trying to stop it from crashing everything I could have finished my whole damn project. 
 
 Below are spit-simple set of extensions to UIView that let you accomplish simple tasks like laying out subviews uniformly along either the x or y axis, and defining the origin of any given view proportionally to its superview. It's a little more work to set up than AutoLayout, but tweaking it, revising it, and debugging it are a _lot_ less work than struggling with AutoLayout.
 
 At the end there are examples that demonstrate functionality.
 */
import UIKit
extension UIView {
  // A convenience func for removing all subviews.
  func removeAllSubviews() {
    subviews.forEach({ $0.removeFromSuperview() })
  }
  
  // A convenience init for making rects that default to origins of 0, 0
  convenience init(size: CGSize, color: UIColor = .yellowColor()) {
    /* background color defaults to yellow */
    let zeroedFrame = CGRectMake(0, 0, size.width, size.height)
    self.init(frame: zeroedFrame)
    backgroundColor = color
  }
  
  // Vertical layout functions
  func layoutVerticallyAtX(x: CGFloat, views:[UIView],
                           margin: CGFloat? = nil) {
    /* lays out given views keeping a consistent gap between them
    defaults to using a margin the same size as the gaps between views */
    //find this view's height less margin
    var operativeHeight = self.frame.height
    if let margin = margin {
      operativeHeight -= (margin * 2)
    }
    //find that less total height of given views
    var viewsHeight: CGFloat = 0
    views.forEach({ viewsHeight += $0.frame.height })
    let availablePadding = operativeHeight - viewsHeight
    //find amount to put between each view
    let spaceBetween = availablePadding / CGFloat(views.count + 1)
    //set a starting y
    var currentY: CGFloat = spaceBetween
    if let margin = margin {
      currentY = margin
    }
    //count through the views
    for view in views {
      // make sure views given as arguments are also subviews
      if !subviews.contains(view) {
        addSubview(view)
      }
      // set the origin of the current view
      view.frame.origin.x = x - (view.frame.width / 2)
      view.frame.origin.y = currentY
      currentY += view.frame.height + spaceBetween
    }
  }
  func layoutVerticallyAtProportionalX(proportion: CGFloat, views: [UIView],
                                       margin: CGFloat? = nil) {
    let calculatedX = self.frame.width * proportion
    self.layoutVerticallyAtX(calculatedX, views: views, margin: margin)
  }
  func layoutVerticallyAtCenter(views:[UIView],  margin: CGFloat? = nil) {
    /* lays out given views at center of self */
    layoutVerticallyAtProportionalX(0.5, views: views, margin: margin)
  }
  
  // Horizontal layout functions
  func layoutHorizontallyAtY(y: CGFloat, views:[UIView],
                             margin: CGFloat? = nil) {
    /* lays out given views keeping a consistent gap between them
     defaults to using a margin the same size as the gaps between views */
    //find this view's width less margin
    var operativeWidth = self.frame.width
    if let margin = margin {
      operativeWidth -= (margin * 2)
    }
    //find that less total width of given views
    var viewsHeight: CGFloat = 0
    views.forEach({ viewsHeight += $0.frame.width })
    let availablePadding = operativeWidth - viewsHeight
    //find amount to put between each view
    let spaceBetween = availablePadding / CGFloat(views.count + 1)
    //set a starting x
    var currentX: CGFloat = spaceBetween
    if let margin = margin {
      currentX = margin
    }
    //count through the views
    for view in views {
      // make sure views given as arguments are also subviews
      if !subviews.contains(view) {
        addSubview(view)
      }
      // set the origin of the current view
      view.frame.origin.y = y - (view.frame.height / 2)
      view.frame.origin.x = currentX
      currentX += view.frame.width + spaceBetween
    }
  }
  func layoutHorizontallyAtProportionalY(proportion: CGFloat, views: [UIView],
                                         margin: CGFloat? = nil) {
    let calculatedY = self.frame.height * proportion
    self.layoutHorizontallyAtY(calculatedY, views: views, margin: margin)
  }
  func layoutHorizontallyAtCenter(views:[UIView], margin: CGFloat? = nil) {
    layoutHorizontallyAtProportionalY(0.5, views: views, margin: margin)
  }
  
  // Proportional placement function, stating proportions as between 0 & 1
  func setOriginProportionallyForSubview(view: UIView, x: CGFloat? = nil, y: CGFloat? = nil){
    if !self.subviews.contains(view) {
      self.addSubview(view)
    }
    if let x = x {
      let absoluteX = self.frame.width * x
      view.frame.origin.x = absoluteX
    }
    if let y = y {
      let absoluteY = self.frame.height * y
      view.frame.origin.y = absoluteY
    }
  }
}

let RECTANGLE = CGSizeMake(100, 65)
let SQUARE = CGSizeMake(50, 50)
let YELLOW = UIColor.yellowColor()
let ORANGE = UIColor.orangeColor()
let SUPERVIEW = UIView(size: CGSizeMake(275, 400), color: ORANGE)

var rectViews = (1...3).map({ _ in UIView(size: SQUARE, color: YELLOW) })
rectViews.append(UIView(size: RECTANGLE, color: YELLOW))

//: ### Examples
//:Can layout given views at any x value of superview.
SUPERVIEW.layoutVerticallyAtX(60, views: rectViews)
//: Can also layout using a value between 0 and 1 to calculate a proportional x value.
SUPERVIEW.layoutVerticallyAtProportionalX(0.8, views: rectViews)
//: A convenience method allows automatically laying out views at center x.
SUPERVIEW.layoutVerticallyAtCenter(rectViews)
//: The same can be done horizontally, at any y value of superview.
SUPERVIEW.layoutHorizontallyAtY(330, views: rectViews)
//: Can also layout using a value between 0 and 1 to calculate a proportional y value.
SUPERVIEW.layoutHorizontallyAtProportionalY(0.2, views: rectViews)
//: And again, a convenience method allows automatic vertical centering.
SUPERVIEW.layoutHorizontallyAtCenter(rectViews)
//: You can place views as proportions of their superview, using values between 0 and 1.
SUPERVIEW.removeAllSubviews()
let rectView = UIView(size: RECTANGLE)
SUPERVIEW.setOriginProportionallyForSubview(rectView, x: 0.1, y: 0.1)
//: And you can modify a single axis proportionally too.
SUPERVIEW.setOriginProportionallyForSubview(rectView, x: 0.6)
SUPERVIEW.setOriginProportionallyForSubview(rectView, y: 0.8)

//: That's it! It's primitive, but it can do a lot of what the StackView can do, and it will never confound you until you're pulling your hair out and screaming with rage. And that's worth something in this fallen world!
