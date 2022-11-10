//
//  ZoomAnimatedTransitioning.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//
//

import UIKit

@objcMembers
open class ZoomAnimatedTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    /// parent image view used for animated transition
    open weak var referenceImageView: UIImageView?
    /// parent slideshow view used for animated transition
    open weak var referenceSlideshowView: ImageSlideshow?

    // must be weak because FullScreenSlideshowViewController has strong reference to its transitioning delegate
    weak var referenceSlideshowController: FullScreenSlideshowViewController?

    var referenceSlideshowViewFrame: CGRect?
    var gestureRecognizer: UIPanGestureRecognizer!
    fileprivate var interactionController: UIPercentDrivenInteractiveTransition?

    /// Enables or disables swipe-to-dismiss interactive transition
    open var slideToDismissEnabled: Bool = true

    /**
        Init the transitioning delegate with a source ImageSlideshow
        - parameter slideshowView: ImageSlideshow instance to animate the transition from
        - parameter slideshowController: FullScreenViewController instance to animate the transition to
     */
    public init(slideshowView: ImageSlideshow, slideshowController: FullScreenSlideshowViewController) {
        self.referenceSlideshowView = slideshowView
        self.referenceSlideshowController = slideshowController

        super.init()

        initialize()
    }

    /**
        Init the transitioning delegate with a source ImageView
        - parameter imageView: UIImageView instance to animate the transition from
        - parameter slideshowController: FullScreenViewController instance to animate the transition to
     */
    public init(imageView: UIImageView, slideshowController: FullScreenSlideshowViewController) {
        self.referenceImageView = imageView
        self.referenceSlideshowController = slideshowController

        super.init()

        initialize()
    }

    func initialize() {
        // Pan gesture recognizer for interactive dismiss
        gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ZoomAnimatedTransitioningDelegate.handleSwipe(_:)))
        gestureRecognizer.delegate = self
        // Append it to a window otherwise it will be canceled during the transition
        UIApplication.shared.keyWindow?.addGestureRecognizer(gestureRecognizer)
    }

    func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        guard let referenceSlideshowController = referenceSlideshowController else {
            return
        }

        let percent = min(max(abs(gesture.translation(in: gesture.view!).y) / 200.0, 0.0), 1.0)

        if gesture.state == .began {
            interactionController = UIPercentDrivenInteractiveTransition()
            referenceSlideshowController.dismiss(animated: true, completion: nil)
        } else if gesture.state == .changed {
            interactionController?.update(percent)
        } else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            let velocity = gesture.velocity(in: referenceSlideshowView)

            if abs(velocity.y) > 500 {
                if let pageSelected = referenceSlideshowController.pageSelected {
                    pageSelected(referenceSlideshowController.slideshow.currentPage)
                }

                interactionController?.finish()
            } else if percent > 0.5 {
                if let pageSelected = referenceSlideshowController.pageSelected {
                    pageSelected(referenceSlideshowController.slideshow.currentPage)
                }

                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }

            interactionController = nil
        }
    }

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController, title: String?) -> UIViewControllerAnimatedTransitioning? {
        if let reference = referenceSlideshowView {
            return ZoomInAnimator(referenceSlideshowView: reference, parent: self)
        } else if let reference = referenceImageView {
            return ZoomInAnimator(referenceImageView: reference, text: title, parent: self)
        } else {
            return nil
        }
    }

    open func animationController(forDismissed dismissed: UIViewController,
                                  referenceView: UIImageView? = nil,
                                  title: String? = nil) -> UIViewControllerAnimatedTransitioning? {
        if let referenceView = referenceView {
            return ZoomOutAnimator(referenceImageView: referenceView, text: title, parent: self)
        } else if let reference = referenceSlideshowView {
            return ZoomOutAnimator(referenceSlideshowView: reference, parent: self)
        } else if let reference = referenceImageView {
            return ZoomOutAnimator(referenceImageView: reference, text: title, parent: self)
        } else {
            return nil
        }
    }

    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

private class PresentationController: UIPresentationController {
    // Needed for interactive dismiss to keep the presenter View Controller visible
    override var shouldRemovePresentersView: Bool {
        return false
    }
}

extension ZoomAnimatedTransitioningDelegate: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }

        if !slideToDismissEnabled {
            return false
        }

        if let currentItem = referenceSlideshowController?.slideshow.currentSlideshowItem, currentItem.isZoomed() {
            return false
        }

        if let view = gestureRecognizer.view {
            let velocity = gestureRecognizer.velocity(in: view)
            return abs(velocity.x) < abs(velocity.y)
        }

        return true
    }
}

@objcMembers
class ZoomAnimator: NSObject {

    weak var referenceImageView: UIImageView?
    weak var referenceSlideshowView: ImageSlideshow?
    var text: String?
    var parent: ZoomAnimatedTransitioningDelegate
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    var completion: (() -> Void)?

    init(referenceSlideshowView: ImageSlideshow, parent: ZoomAnimatedTransitioningDelegate) {
        self.referenceSlideshowView = referenceSlideshowView
        self.referenceImageView = referenceSlideshowView.currentSlideshowItem?.imageView
        self.parent = parent
        super.init()
    }

    init(referenceImageView: UIImageView, text: String?, parent: ZoomAnimatedTransitioningDelegate) {
        self.referenceImageView = referenceImageView
        self.text = text
        self.parent = parent
        super.init()
    }
}
