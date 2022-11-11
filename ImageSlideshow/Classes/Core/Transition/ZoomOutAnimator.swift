//
//  ZoomOutAnimator.swift
//  
//
//  Created by Kondamon on 10.11.22.
//

import UIKit

class ZoomOutAnimator: ZoomAnimator, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2 // small durations can have not finished spring animation! (frame jumps)
    }

    private func animationParams(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let toViewController: UIViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!

        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? FullScreenSlideshowViewController else {
            fatalError("Transition not used with FullScreenSlideshowViewController")
        }

        let containerView = transitionContext.containerView

        var transitionViewInitialFrame: CGRect
        if let currentSlideshowItem = fromViewController.slideshow.currentSlideshowItem {
            if let image = currentSlideshowItem.imageView.image {
                transitionViewInitialFrame = image.tgr_aspectFitRectForSize(currentSlideshowItem.imageView.frame.size)
            } else {
                transitionViewInitialFrame = currentSlideshowItem.imageView.frame
            }
            transitionViewInitialFrame = containerView.convert(transitionViewInitialFrame, from: currentSlideshowItem)
        } else {
            transitionViewInitialFrame = fromViewController.slideshow.frame
        }

        let transitionViewFinalFrame = getFinalFrame(containerView,
                                                     fromViewController,
                                                     toViewController)

        // transition views
        let transitionBackgroundView = UIView(frame: containerView.frame)
        transitionBackgroundView.backgroundColor = fromViewController.backgroundColor
        containerView.addSubview(transitionBackgroundView)
       
        let transitionView = TransitionImageView()
        transitionView.image = fromViewController.slideshow.currentSlideshowItem?.imageView.image
        transitionView.updateView(title: text)
        transitionView.layer.cornerRadius = 6
        transitionView.frame = transitionViewInitialFrame
        transitionView.setNeedsLayout()
        transitionView.layoutIfNeeded()
        containerView.addSubview(transitionView)
        fromViewController.view.isHidden = true
        if toViewController.view.superview == nil { // pop from navigationController
            transitionContext.containerView.insertSubview(toViewController.view,
                                                          belowSubview: fromViewController.view)
        }
        
        // animation
        animateViews(transitionContext,
                     transitionView,
                     transitionViewFinalFrame,
                     transitionBackgroundView)
        
        self.completion = { [weak self,
                             weak transitionContext,
                             weak fromViewController,
                             weak transitionView, weak transitionBackgroundView] in
            guard let strongSelf = self else { return }
            let completed = !(transitionContext?.transitionWasCancelled ?? false)
            strongSelf.referenceImageView?.alpha = 1

            if completed {
                fromViewController?.view.removeFromSuperview()
                UIApplication.shared.keyWindow?.removeGestureRecognizer(strongSelf.parent.gestureRecognizer)
                // Unpauses slideshow
                strongSelf.referenceSlideshowView?.unpauseTimer()
            } else {
                fromViewController?.view.isHidden = false
            }

            UIView.animate(withDuration: 0.2, delay: 0,
                           options: .allowUserInteraction,
                           animations: {
                transitionView?.alpha = 0
            }, completion: { _ in
                transitionView?.removeFromSuperview()
                transitionBackgroundView?.removeFromSuperview()
            })
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        animationParams(using: transitionContext)
    }
    
    private func getFinalFrame(_ containerView: UIView,
                                   _ fromViewController: FullScreenSlideshowViewController,
                                   _ toViewController: UIViewController) -> CGRect {
        var transitionViewFinalFrame: CGRect
        if let referenceImageView = referenceImageView {
            referenceImageView.alpha = 0
            
            let referenceSlideshowViewFrame = containerView.convert(referenceImageView.bounds, from: referenceImageView)
            transitionViewFinalFrame = referenceSlideshowViewFrame
            
            // do a frame scaling when AspectFit content mode enabled
            if fromViewController.slideshow.currentSlideshowItem?.imageView.image != nil && referenceImageView.contentMode == UIViewContentMode.scaleAspectFit {
                transitionViewFinalFrame = containerView.convert(referenceImageView.aspectToFitFrame(), from: referenceImageView)
            }
            
            // fixes the problem when the referenceSlideshowViewFrame was shifted during change of the status bar hidden state
            if UIApplication.shared.isStatusBarHidden && !toViewController.prefersStatusBarHidden && referenceSlideshowViewFrame.origin.y != parent.referenceSlideshowViewFrame?.origin.y {
                transitionViewFinalFrame = transitionViewFinalFrame.offsetBy(dx: 0, dy: 20)
            }
        } else {
            transitionViewFinalFrame = referenceSlideshowView?.frame ?? CGRect.zero
        }
        
        return transitionViewFinalFrame
    }
    
    /// Animation of all views
    private func animateViews(_ transitionContext: UIViewControllerContextTransitioning,
                              _ transitionImageTextView: TransitionImageView?,
                              _ transitionViewFinalFrame: CGRect,
                              _ transitionBackgroundView: UIView) {
        let duration: TimeInterval = transitionDuration(using: transitionContext)
        
        if let transitionView = transitionImageTextView {
            // Movement of image
            let group1Animation = transitionView.layer.resizeAndMove(frame: transitionViewFinalFrame,
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
        
        transitionBackgroundView.alpha = 1
        transitionImageTextView?.hideLabel()
        UIView.animate(withDuration: duration, delay: 0, animations: { [weak transitionBackgroundView] in
            transitionBackgroundView?.alpha = 0
        })
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        completion?()
        self.transitionContext?.completeTransition(!(self.transitionContext?.transitionWasCancelled ?? false))
    }
}
