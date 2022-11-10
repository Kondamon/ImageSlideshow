//
//  ZoomInAnimator.swift
//  
//
//  Created by Kondamon on 10.11.22.
//

import UIKit

@objcMembers
class ZoomInAnimator: ZoomAnimator, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        // Pauses slideshow
        self.referenceSlideshowView?.pauseTimer()

        let containerView = transitionContext.containerView
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!

        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? FullScreenSlideshowViewController else {
            return
        }

        toViewController.view.frame = transitionContext.finalFrame(for: toViewController)

        let transitionBackgroundView = UIView(frame: containerView.frame)
        transitionBackgroundView.backgroundColor = toViewController.backgroundColor
        containerView.addSubview(transitionBackgroundView)

        toViewController.view.layoutIfNeeded() // get default size (without safeAreaInsets)
        let safeAreaHeightInsets = fromViewController.view.safeAreaInsets.top + fromViewController.view.safeAreaInsets.bottom
        let realHeight = (toViewController.slideshow.slideshowItems.first?.frame.height ?? 1000) - safeAreaHeightInsets
        let safeAreaHeightAndConstants = fromViewController.view.safeAreaInsets.top + toViewController.slideshow.frame.minY
        let statusBarOffset: CGFloat = UIApplication.shared.isStatusBarHidden && toViewController.prefersStatusBarHidden ? 20 : 0
        let finalFrame = CGRect(origin: CGPoint(x: 0, y: safeAreaHeightAndConstants - statusBarOffset),
                                size: CGSize(width: toViewController.view.frame.width,
                                             height: realHeight + statusBarOffset))

        var transitionImageTextView: TransitionImageView?
        var transitionViewFinalFrame = finalFrame
        if let referenceImageView = referenceImageView {
            transitionImageTextView = TransitionImageView()
            transitionImageTextView?.image = referenceImageView.image
            transitionImageTextView?.frame = containerView.convert(referenceImageView.bounds, from: referenceImageView)
            transitionImageTextView?.updateView(title: text)
            containerView.addSubview(transitionImageTextView!)
            transitionImageTextView?.layoutIfNeeded()
            self.parent.referenceSlideshowViewFrame = transitionImageTextView!.frame
            if let image = referenceImageView.image {
                transitionViewFinalFrame = image.tgr_aspectFitRectForSize(finalFrame.size)
            }
        }

        if let item = toViewController.slideshow.currentSlideshowItem, item.zoomInInitially {
            transitionViewFinalFrame.size = CGSize(width: transitionViewFinalFrame.size.width * item.maximumZoomScale,
                                                   height: transitionViewFinalFrame.size.height * item.maximumZoomScale)
        }

        animateViews(transitionContext, transitionImageTextView, finalFrame, transitionViewFinalFrame, transitionBackgroundView)
        
        self.completion = { [weak containerView,
                             weak toViewController,
                             weak fromViewController,
                             weak transitionBackgroundView] in
            if let toViewController = toViewController {
                containerView?.addSubview(toViewController.view)
            }
            transitionImageTextView?.removeFromSuperview()
            fromViewController?.view.alpha = 1
            transitionBackgroundView?.removeFromSuperview()
        }
    }
    
    /// Animation of all views
    private func animateViews(_ transitionContext: UIViewControllerContextTransitioning,
                              _ transitionImageTextView: TransitionImageView?,
                              _ finalFrame: CGRect,
                              _ transitionViewFinalFrame: CGRect,
                              _ transitionBackgroundView: UIView) {
        let duration: TimeInterval = transitionDuration(using: transitionContext)
        
        if let transitionView = transitionImageTextView {
            // Movement of image
            let centeredInRect = CGRect(x: finalFrame.midX - transitionViewFinalFrame.width / 2,
                                        y: finalFrame.midY - transitionViewFinalFrame.height / 2,
                                        width: transitionViewFinalFrame.width,
                                        height: transitionViewFinalFrame.height)
            let group1Animation = transitionView.layer.resizeAndMove(frame: centeredInRect,
                                                                     duration: duration,
                                                                     fillMode: .forwards)
            group1Animation.delegate = self // to call stop of transition and completion
            transitionView.layer.add(group1Animation, forKey: "Resize and move view")
            
            // Movement of CAGradient layer (to better see text)
            let group2Animation = transitionView.textOverlay.imageOverlayGradientLayer.resizeAndMove(frame: CGRect(x: 0,
                                                                                                                   y: transitionViewFinalFrame.height / 2,
                                                                                                                   width: transitionViewFinalFrame.width,
                                                                                                                   height: transitionViewFinalFrame.height / 2),
                                                                                                     duration: duration,
                                                                                                     fillMode: .forwards)
            transitionView.textOverlay.imageOverlayGradientLayer.add(group2Animation, forKey: "resize and move gradient layer")
        }
        
        transitionBackgroundView.alpha = 0
        transitionImageTextView?.hideLabel()
        UIView.animate(withDuration: duration, delay: 0, animations: { [weak transitionBackgroundView] in
            transitionBackgroundView?.alpha = 1
        })
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion?()
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
    }
}

extension CALayer {

    private func configureAnimation(_ animation: CASpringAnimation) {
        animation.damping = 20
        animation.stiffness = 200
        animation.initialVelocity = 5
    }
    
    func resizeAndMove(frame: CGRect, duration: TimeInterval, fillMode: CAMediaTimingFillMode) -> CAAnimationGroup {
       
        let positionAnimation = CASpringAnimation(keyPath: "position")
        positionAnimation.fromValue = value(forKey: "position")
        positionAnimation.toValue = NSValue(cgPoint: CGPoint(x: frame.midX, y: frame.midY))
        configureAnimation(positionAnimation)
        
        let oldBounds = bounds
        var newBounds = oldBounds
        newBounds.size = frame.size
        
        let boundsAnimation = CASpringAnimation(keyPath: "bounds")
        boundsAnimation.fromValue = NSValue(cgRect: oldBounds)
        boundsAnimation.toValue = NSValue(cgRect: newBounds)
        configureAnimation(boundsAnimation)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [positionAnimation, boundsAnimation]
        groupAnimation.fillMode = fillMode
        groupAnimation.duration = duration
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        groupAnimation.isRemovedOnCompletion = false
        
        return groupAnimation
    }
}
