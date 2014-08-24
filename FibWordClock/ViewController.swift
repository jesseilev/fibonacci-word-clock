//
//  ViewController.swift
//  FibWordClock
//
//  Created by Jesse Levine on 8/22/14.
//  Copyright (c) 2014 jesselevine. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController  {
    
    @IBOutlet var hourLabel: UILabel
    @IBOutlet var secondsLabel: UILabel
    @IBOutlet var wordContainerView: UIView
    
    var rootWord = FibonacciWord.rootWord()
    weak var rootWordView: UIView?
    var wordViews = NSMutableDictionary()
    
    var timeChunks: [ (calendarUnit: NSCalendarUnit, size: Int) ] = [ (.CalendarUnitHour, 24), (.CalendarUnitHour, 12), (.CalendarUnitHour, 1), (.CalendarUnitMinute, 30), (.CalendarUnitMinute, 15), (.CalendarUnitMinute, 5), (.CalendarUnitMinute, 1), (.CalendarUnitSecond, 30), (.CalendarUnitSecond, 10), (.CalendarUnitSecond, 1) ]
    
    var timer: NSTimer?

    //#pragma mark VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let notificationNames = ["didEnterBackground", "willEnterForeground", "didBecomeActive"]
        for name in notificationNames {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleNotification:"), name: name, object: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        installRootWordView()
    }
    
    override func viewDidAppear(animated: Bool) {
        //This should really be inside viewDidLayoutSubviews(), but for some reason the frames aren't set properly there.
        setupUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //#pragma mark UI
    
    func setupUI() {
        
        refreshColors()
        refreshLabels()

        let currentTime = NSDate.date() //NSDate(timeIntervalSince1970: 5.999 * 60 * 60 )
        for object in wordViews.allValues {
            if let wordView = object as? UIView {
                let smallerDimension = min(wordView.frame.size.width, wordView.frame.size.height)
                wordView.layer.cornerRadius = smallerDimension * 0.5
            }
        }
        
        for key in wordViews.allKeys {
            //Make a separate loop through wordViews for this; we want the animations to be created at similar time to each other
            if let indexPath = key as? [Int] {
                addAnimations(indexPath: indexPath, synchronizedCurrentTime: currentTime)
            }
        }
        resumeAllLayerAnimations()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("receiveTimer:"), userInfo: nil, repeats: true)
        
        if let uwRootWordView = rootWordView { uwRootWordView.hidden = false }
    }
    
    func installRootWordView() {
        rootWordView?.removeFromSuperview()
        rootWordView = viewForWord(rootWord, depth: timeChunks.count - 1)
        wordContainerView.addSubview(rootWordView!)
        wordContainerView.autolayoutInsetSubview(rootWordView!, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        rootWordView!.layer.borderWidth = 1.0
        rootWordView!.hidden = true
    }
    
    func viewForWord(word: FibonacciWord, depth: Int) -> UIView {
        let wordView = UIView.autolayoutView()
        wordViews[word.indexPath] = wordView
        wordView.autolayoutSetAspectRatio(1)
        wordView.layer.borderWidth = vs * 2.0
        
        if depth > 0 {
            let letterBSubview = viewForWord(word.letterBSubword, depth: depth - 1)
            wordView.addSubview(letterBSubview)
            wordView.autolayoutCenterSubview(letterBSubview, attribute: .CenterX)
            
            let letterBName = "bSub"
            var viewNames = [letterBName : letterBSubview]
            
            let letterAName = "aSub"
            if let uwAWord = word.letterASubword {
                let letterASubview = viewForWord(uwAWord, depth: depth - 1)
                wordView.addSubview(letterASubview)
                viewNames[letterAName] = letterASubview
                
                //Make room for letterASubview below letterBSubview. Create a constraint on letterBSubview's height.
                wordView.addConstraint( NSLayoutConstraint(item: letterBSubview, attribute: .Width, relatedBy: .Equal, toItem: wordView, attribute: .Height, multiplier: phiInverse, constant: 0) )
            }
            
            let blankOrLetterA = (!word.letterASubword) ? "" : "[\(letterAName)]-\(vs)-"
            var vFormatString = "V:|-\(vs)-[bSub]-\(vs)-\(blankOrLetterA)|"
            wordView.addConstraints( NSLayoutConstraint.constraintsWithVisualFormat(vFormatString, options: .AlignAllCenterX, metrics: nil, views: viewNames) )
        }
        
        return wordView
    }
    
    var hourHue: CGFloat = 0.0
    var minuteHue: CGFloat = 0.0
    /**
    * Use the current time to determine the wordViews' colors.
    */
    func refreshColors() {
        
        let components = NSCalendar.currentCalendar().components( .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit, fromDate: NSDate.date())
        //hourHue and minuteHue get their values based on the current hour and minute.
        hourHue = 1.0 - CGFloat(components.hour % 12) / 12.0
        minuteHue = CGFloat(components.minute) / 60.0
        //We now use hourHue and minuteHue to form a range of possible hues. All views will be colored with a hue somewhere in between the two values. Colors toward the back (rootView) will have a hue approaching hourHue, and colors toward the front will have a hue approaching minuteHue.
        
        
        //Once hues are determined, similar ranges can be calculated for brightness and saturation.
        //Brightness depends on the hour. At 3am, the back is dark and the front is light; at 3pm the back is light and front is dark.
        var distanceFrom3AM = min(abs(components.hour - 3), abs(components.hour - 27))
        var backBrightness = CGFloat(distanceFrom3AM) / 12.0
        var frontBrightness = 1.0 - backBrightness
        
        //Saturation decreases as brightness increases. The range of possible saturations expands as the range of possible hues contracts, and vice-versa.
        var satRange = (1.0 - abs(hourHue - minuteHue))
        var backSaturation = 0.5 + (0.5 * satRange)
        var frontSaturation = 0.5 - (0.5 * satRange)
        
        for (key, object) in wordViews {
            if let indexPath = key as? [Int] {
                if let wordView = object as? UIView {
                    let depthPct = CGFloat(indexPath.count) / CGFloat(timeChunks.count - 1)
                    let hue = hourHue + (depthPct * (minuteHue - hourHue) )
                    let brightness = backBrightness + (depthPct * (frontBrightness - backBrightness))
                    let saturation = backSaturation + (depthPct * (frontSaturation - backSaturation))
                    let layerColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
                    wordView.layer.backgroundColor = layerColor.CGColor
                    
                    //The view's layer has an ongoing animation to adjust its alpha, which uses .backgroundColor as the changing property. We need to go in and reset the animation's toValue and fromValue, using our new color
                    if let animationGroup = wordView.layer.animationForKey("animationSequence") as? CAAnimationGroup {
                        //look for the alpha animation
                        var alphaAnim: CABasicAnimation?
                        for animation in animationGroup.animations {
                            if let name = animation.valueForKey("name") as? String {
                                if name == "repeatingAlphaAnimation" {
                                    alphaAnim = (animation as CABasicAnimation)
                                }
                            }
                        }
                        if let uwAlphaAnim = alphaAnim {
                            uwAlphaAnim.fromValue = layerColor.colorWithAlphaComponent(0)
                            uwAlphaAnim.toValue = layerColor.colorWithAlphaComponent(1)
                            //TODO CoreAnimation possibly ignores this
                            wordView.backgroundColor = layerColor // In case the adjustment is being ignored, at least we can correctly set the backgroundColor of the view itself, which will show through whenever the layer's alpha is at a low point.
                        }
                    }
                }
            }
        }
        
        //Adjust the colors of various UI components
        let backColor = UIColor(hue: hourHue, saturation: backSaturation, brightness: backBrightness, alpha: 1)
        let frontColor = UIColor(hue: minuteHue, saturation: frontSaturation, brightness: frontBrightness, alpha: 1)
        self.view.backgroundColor = backColor
        hourLabel.textColor = frontColor
        secondsLabel.textColor = frontColor
        if let uwRootWordView = rootWordView {
            uwRootWordView.layer.borderColor = frontColor.CGColor
        }
    }
    
    func refreshLabels() {
        hourLabel.hidden = false
        secondsLabel.hidden = false
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        hourLabel.text = formatter.stringFromDate(NSDate.date())
        formatter.dateFormat = "ss"
        secondsLabel.text = "and " + formatter.stringFromDate(NSDate.date())
    }
    
    func receiveTimer(timer: NSTimer) {
        refreshLabels()
        
        //If a new minute has begun, refreshColors()
        let components = NSCalendar.currentCalendar().components(.CalendarUnitSecond, fromDate: NSDate.date())
        if components.second == 0 {
            refreshColors()
        }
    }
    
    //#pragma mark Animations
    
    /*
    * Add animations to the wordView located at the specified indexPath.
        The view should repeatedly rotate 360 degrees, and fade its alpha in and out.
        The period of the view's animation cycle is determined by its corresponding FibonacciWord. 
        The word's position within self.rootWord's subword hiearchy tells us how fast or slow to play the animation.
        Words located toward the root will cycle slower, whereas those toward the "leaves" of the hierarchy cycle faster. 
        The exact cycle-time is determined by grabbing the appropriate entry from self.timeChunks.
    */
    func addAnimations(#indexPath: [Int], synchronizedCurrentTime: NSDate) {
        if let wordView = wordViews[indexPath] as? UIView {
            if let word = rootWord.subwordAtIndexPath(indexPath) {
                
                wordView.layer.removeAllAnimations()
                
                var timeChunk = timeChunks[indexPath.count] //There are a lot of variables here that could be constants, but I'm using variables for debugging purposes. The current debugger for XCode6 won't let us inspect the values of constants.
                var fullCycleDuration = Double(timeChunk.size) * timeChunk.calendarUnit.timeInterval()
                var fullCircle = CGFloat(M_PI * 2.0)

                var timeComponents = NSCalendar.currentCalendar().components( .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit, fromDate: synchronizedCurrentTime)
                var intervalCompleted = intervalFromComponents(timeComponents, timeChunk: timeChunk)
                intervalCompleted = intervalCompleted % fullCycleDuration
                var percentCompleted = intervalCompleted / fullCycleDuration
                var oneTimeAnimDuration = (1.0 - percentCompleted) * fullCycleDuration

                var animations = [CABasicAnimation]()

                var shouldRotate = true
                if let superWordLetter = word.superword?.letter {
                    if superWordLetter.toRaw() == 1 {
                        //If word.superword's letter is .A, that means wordView is the only subView of its superview. We dont want to rotate wordView because its superView is already rotating, and these two views should act as one because the subview fills the entirety of the superview's bounds.
                        shouldRotate = false
                    }
                }
                if shouldRotate {
                    //Create a one-time animation to rotate from the current time's offset back to a rotation value of 0
                    var fromTransform = CGFloat(percentCompleted) * fullCircle
                    var toTransform = fullCircle
                    
                    let onceRotationAnim = CABasicAnimation(keyPath: "transform.rotation.z")
                    onceRotationAnim.fromValue = fromTransform
                    onceRotationAnim.toValue = toTransform
                    onceRotationAnim.cumulative = true
                    onceRotationAnim.duration = oneTimeAnimDuration
                    onceRotationAnim.delegate = self
                    onceRotationAnim.setValue(wordView.layer, forKey: "layer")
                    
                    //Create a repeated rotation animation. Simply rotate 360 degrees.
                    var repeatDuration = fullCycleDuration * 0.25
                    let repeatRotationAnim = CABasicAnimation(keyPath: "transform.rotation.z")
                    //if word.letter.toRaw() == 1 { toTransform *= -1 }
                    repeatRotationAnim.toValue = toTransform * 0.25
                    repeatRotationAnim.duration = repeatDuration
                    repeatRotationAnim.beginTime = onceRotationAnim.duration
                    repeatRotationAnim.cumulative = true
                    repeatRotationAnim.repeatCount = repeatCount
                    repeatRotationAnim.delegate = self
                    repeatRotationAnim.setValue(wordView.layer, forKey: "layer")
                    
                    animations += onceRotationAnim
                    animations += repeatRotationAnim
                }

                //Now for the alpha animations. Apply alpha animations to all views except for the ones at the very lowest-level, aka the ones with no subviews
                if indexPath.count < timeChunks.count - 1 { //Go ahead if wordView is not at the lowest level
                    
                    //The view should fade in and then back out exactly once over the course of one cycle. The alpha property should start at 0, build to 1 halfway through the cycle, and then fade back to 0, then smoothly repeat in sync with the next cycle.
                    
                    let layerColor = UIColor(CGColor: wordView.layer.backgroundColor)
                    
                    //Before apply a repeating animation, we need to account for the current time offset and animate "back to square-one". This will require either one or two nonrepeating animations.
                    
                    var oneTimeFadeInAnim: CABasicAnimation?
                    //If we are beginning less than halfway through the cycle...
                    if percentCompleted < 0.5 {
                        //Create a one-time alpha fade-in animation. Should start at a level determined by current time's offset, and build up to 1.
                        var fromAlpha = CGFloat(percentCompleted * 2.0)
                        var fadeInDuration = Double(1.0 - fromAlpha) * (0.5 * fullCycleDuration)

                        oneTimeFadeInAnim = CABasicAnimation(keyPath: "backgroundColor") // Modify the background color rather than the layer's actual alpha property, because we dont want the opacity of the layer itself to change, because that would affect the layer's view's subviews.
                        oneTimeFadeInAnim!.fromValue = layerColor.colorWithAlphaComponent(fromAlpha).CGColor
                        oneTimeFadeInAnim!.toValue = layerColor.colorWithAlphaComponent(1).CGColor
                        oneTimeFadeInAnim!.autoreverses = true
                        oneTimeFadeInAnim!.duration = fadeInDuration
                        animations += oneTimeFadeInAnim!
                    }
                    
                    //In all cases, we must create a one-time alpha fade-out animation.
                    var fadeOutBegin: Double = 0
                    var fadeOutDuration = oneTimeAnimDuration % (0.5 * fullCycleDuration)
                    var fadeOutFromAlpha = 1.0 - ( (CGFloat(percentCompleted) - 0.5 ) / 0.5)
                    if let uwFadeIn = oneTimeFadeInAnim {
                        //If we faded in first, these values change
                        fadeOutBegin = uwFadeIn.duration
                        fadeOutDuration = 0.5 * fullCycleDuration
                        fadeOutFromAlpha = 1
                    }
                    let oneTimeFadeOutAnim = CABasicAnimation(keyPath: "backgroundColor")
                    oneTimeFadeOutAnim.fromValue = layerColor.colorWithAlphaComponent(fadeOutFromAlpha).CGColor
                    oneTimeFadeOutAnim.toValue = layerColor.colorWithAlphaComponent(0).CGColor
                    oneTimeFadeOutAnim.duration = fadeOutDuration
                    oneTimeFadeOutAnim.beginTime = fadeOutBegin
                    animations += oneTimeFadeOutAnim
                    
                    //Create a repeating alpha fade-in-out animation over the duration of 1 full cycle. Start at alpha = 0, and build up to 1 at halfway through the cycle, then autoreverse.
                    let repeatingAlphaAnim = CABasicAnimation(keyPath: "backgroundColor")
                    repeatingAlphaAnim.fromValue = layerColor.colorWithAlphaComponent(0).CGColor
                    repeatingAlphaAnim.toValue = layerColor.colorWithAlphaComponent(1).CGColor
                    repeatingAlphaAnim.autoreverses = true
                    repeatingAlphaAnim.duration = fullCycleDuration * 0.5
                    repeatingAlphaAnim.beginTime = oneTimeAnimDuration //* 2.0
                    repeatingAlphaAnim.repeatCount = repeatCount
                    repeatingAlphaAnim.setValue("repeatingAlphaAnimation", forKey: "name")
                    
                    animations += repeatingAlphaAnim
                }
                
                //If we have any animations, group them together and add them to the layer
                if animations.count > 0 {
                    let sequence = CAAnimationGroup()
                    sequence.animations = animations
                    sequence.duration = oneTimeAnimDuration + (fullCycleDuration * Double(repeatCount))
                    wordView.layer.addAnimation(sequence, forKey: "animationSequence")
                }
                
                //Immediately pause the layer's new animations. Elsewhere we will manually resume all the layers together at once, to try to ensure synchronous timing.
                pauseLayer(wordView.layer)
            }
        }
    }
    
    func pauseLayer(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func pauseAllLayerAnimations() {
        for object in wordViews.allValues {
            if let wordView = object as? UIView {
                pauseLayer(wordView.layer)
            }
        }
    }
    
    func resumeAllLayerAnimations() {
        for object in wordViews.allValues {
            if let wordView = object as? UIView {
                resumeLayer(wordView.layer)
            }
        }
    }
    
    //#pragma mark Helpers
    
    func intervalFromComponents(components: NSDateComponents, timeChunk: (calendarUnit:  NSCalendarUnit, size: Int)) -> Double {
        if timeChunk.calendarUnit == .MinuteCalendarUnit {
            components.hour = 0
        }
        if timeChunk.calendarUnit == .SecondCalendarUnit {
            components.minute == 0
        }
        var interval = Double(components.hour % timeChunk.size) * NSCalendarUnit.HourCalendarUnit.timeInterval() + Double(components.minute) * NSCalendarUnit.MinuteCalendarUnit.timeInterval() + Double(components.second) * NSCalendarUnit.SecondCalendarUnit.timeInterval()
        return interval
    }
    
    
    //#pragma mark Constants
    
    let vs: CGFloat = 0.0 //default vertical spacing between neighbor wordViews
    
    let phiInverse: CGFloat = 0.618
    
    let repeatCount: CGFloat = 10000 //for repeating animations

    
    //#pragma mark ViewController management
    
    func handleNotification(notification: NSNotification) {
        if notification.name == "didEnterBackground" {
            timer?.invalidate()
        }
        else if notification.name == "willEnterForeground" {
            installRootWordView()
            self.view.layoutSubviews()
        }
        else if notification.name == "didBecomeActive" {
            setupUI()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

