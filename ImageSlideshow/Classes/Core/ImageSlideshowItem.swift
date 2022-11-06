//
//  ZoomablePhotoView.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 30.07.15.
//

import UIKit

/// Used to wrap a single slideshow item and allow zooming on it
@objcMembers
open class ImageSlideshowItem: UIScrollView, UIScrollViewDelegate {

    /// Image view to hold the image
    public let imageView = UIImageView()
    
    public private(set) var customView: UIView?
    
    /// To be able to better see text
    private lazy var imageOverlayGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, // top
                           UIColor.black.withAlphaComponent(0.6).cgColor]

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.isHidden = true
        return gradient
    }()
    
    public lazy var label: CenteredBottomTextView = {
        let textView = CenteredBottomTextView()
        textView.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        textView.textColor = .white
        textView.textAlignment = .center
        textView.isUserInteractionEnabled = false
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        textView.isSelectable = false
        textView.textContainer.lineFragmentPadding = 0
   
        return textView
    }()
    
    /// Activity indicator shown during image loading, when nil there won't be shown any
    public let activityIndicator: ActivityIndicatorView?

    /// Input Source for the item
    public let image: InputSource

    /// Guesture recognizer to detect double tap to zoom
    open var gestureRecognizer: UITapGestureRecognizer?

    /// Holds if the zoom feature is enabled
    public let zoomEnabled: Bool

    /// If set to true image is initially zoomed in
    open var zoomInInitially = false

    /// Maximum zoom scale
    open var maximumScale: CGFloat = 2.0

    fileprivate var lastFrame = CGRect.zero
    fileprivate var imageReleased = false
    fileprivate var isLoading = false
    fileprivate var singleTapGestureRecognizer: UITapGestureRecognizer?
    fileprivate var loadFailed = false {
        didSet {
            singleTapGestureRecognizer?.isEnabled = loadFailed
            gestureRecognizer?.isEnabled = !loadFailed
        }
    }

    /// Wraps around ImageView so RTL transformation on it doesn't interfere with UIScrollView zooming
    private let imageViewWrapper = UIView()

    // MARK: - Life cycle

    /**
        Initializes a new ImageSlideshowItem
        - parameter image: Input Source to load the image
        - parameter zoomEnabled: holds if it should be possible to zoom-in the image
    */
    init(image: InputSource, zoomEnabled: Bool, activityIndicator: ActivityIndicatorView? = nil, maximumScale: CGFloat = 2.0) {
        self.zoomEnabled = zoomEnabled
        self.image = image
        self.activityIndicator = activityIndicator
        self.maximumScale = maximumScale

        super.init(frame: CGRect.null)
        imageViewWrapper.addSubview(imageView)
        if let customView = image.getView?() {
            self.customView = customView
            imageViewWrapper.addSubview(customView)
            imageViewWrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = .image
        imageView.layer.addSublayer(imageOverlayGradientLayer)
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        imageViewWrapper.clipsToBounds = true
        imageViewWrapper.isUserInteractionEnabled = true
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            imageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }

        setPictoCenter()

        // scroll view configuration
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        addSubview(imageViewWrapper)
        minimumZoomScale = 1.0
        maximumZoomScale = calculateMaximumScale()

        if let activityIndicator = activityIndicator {
            addSubview(activityIndicator.view)
        }
        imageView.addSubview(label)
        
        // tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImageSlideshowItem.tapZoom))
        tapRecognizer.numberOfTapsRequired = 2
        imageViewWrapper.addGestureRecognizer(tapRecognizer)
        gestureRecognizer = tapRecognizer

        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(retryLoadImage))
        singleTapGestureRecognizer!.numberOfTapsRequired = 1
        singleTapGestureRecognizer!.isEnabled = false
        imageViewWrapper.addGestureRecognizer(singleTapGestureRecognizer!)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if !zoomEnabled {
            imageViewWrapper.frame.size = frame.size
        } else if !isZoomed() {
            imageViewWrapper.frame.size = calculatePictureSize()
        }

        if isFullScreen() {
            clearContentInsets()
        } else {
            setPictoCenter()
        }
        
        customView?.frame.size = CGSize(width: self.frame.width, height: customView?.intrinsicContentSize.height ?? 0)
        customView?.center = CGPoint(x: imageViewWrapper.bounds.midX, y: imageViewWrapper.bounds.midY)
        self.activityIndicator?.view.center = imageViewWrapper.center
        self.label.frame = imageView.bounds
        imageOverlayGradientLayer.frame = CGRect(x: 0,
                                                 y: (imageView.bounds.maxY - imageView.bounds.minY) / 2,
                                                 width: imageView.bounds.width,
                                                 height: imageView.bounds.height / 2)

        // if self.frame was changed and zoomInInitially enabled, zoom in
        if lastFrame != frame && zoomInInitially {
            setZoomScale(maximumZoomScale, animated: false)
        }

        lastFrame = self.frame

        contentSize = imageViewWrapper.frame.size
        maximumZoomScale = calculateMaximumScale()
        
        imageOverlayGradientLayer.isHidden = label.text.isEmpty
        if #available(iOS 13.0, *) {
            updateFontsAndMargins()
        }
    }
    
    @available(iOS 13.0, *)
    private func updateFontsAndMargins() {
        let generator = ItemSettingGenerator()
        let settings = generator.getSettings(self.imageView.bounds.size, mode: .element)
        label.font = settings.titleFont
        // label.centerBottomText(margin: settings.margins.bottom)
        label.textContainerInset.left = settings.margins.left
        label.textContainerInset.right = settings.margins.right
    }

    /// Request to load Image Source to Image View
    public func loadImage() {
        if self.imageView.image == nil && !isLoading {
            isLoading = true
            imageReleased = false
            activityIndicator?.show()
            image.load(to: self.imageView) {[weak self] image in
                // set image to nil if there was a release request during the image load
                if let imageRelease = self?.imageReleased, imageRelease {
                    self?.imageView.image = nil
                } else {
                    self?.imageView.image = image
                }
                self?.activityIndicator?.hide()
                self?.loadFailed = image == nil
                self?.isLoading = false

                self?.setNeedsLayout()
            }
        }
    }

    func releaseImage() {
        imageReleased = true
        cancelPendingLoad()
        self.imageView.image = nil
    }

    public func cancelPendingLoad() {
        image.cancelLoad?(on: imageView)
    }

    func retryLoadImage() {
        self.loadImage()
        guard customView != nil else { return }
        guard let activeTextField = UIResponder.currentFirst() as? UIView else { return }
        activeTextField.resignFirstResponder()
    }

    // MARK: - Image zoom & size

    func isZoomed() -> Bool {
        return self.zoomScale != self.minimumZoomScale
    }

    func zoomOut() {
        self.setZoomScale(minimumZoomScale, animated: false)
    }

    func tapZoom() {
        if isZoomed() {
            self.setZoomScale(minimumZoomScale, animated: true)
        } else {
            self.setZoomScale(maximumZoomScale, animated: true)
        }
    }

    fileprivate func screenSize() -> CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }

    fileprivate func calculatePictureSize() -> CGSize {
        if let image = imageView.image, imageView.contentMode == .scaleAspectFit {
            let picSize = image.size
            let picRatio = picSize.width / picSize.height
            let screenRatio = screenSize().width / screenSize().height

            if picRatio > screenRatio {
                return CGSize(width: screenSize().width, height: screenSize().width / picSize.width * picSize.height)
            } else {
                return CGSize(width: screenSize().height / picSize.height * picSize.width, height: screenSize().height)
            }
        } else {
            return CGSize(width: screenSize().width, height: screenSize().height)
        }
    }

    fileprivate func calculateMaximumScale() -> CGFloat {
        return maximumScale
    }

    fileprivate func setPictoCenter() {
        var intendHorizon = (screenSize().width - imageViewWrapper.frame.width ) / 2
        var intendVertical = (screenSize().height - imageViewWrapper.frame.height ) / 2
        intendHorizon = intendHorizon > 0 ? intendHorizon : 0
        intendVertical = intendVertical > 0 ? intendVertical : 0
        contentInset = UIEdgeInsets(top: intendVertical, left: intendHorizon, bottom: intendVertical, right: intendHorizon)
    }

    private func isFullScreen() -> Bool {
        return imageViewWrapper.frame.width >= screenSize().width && imageViewWrapper.frame.height >= screenSize().height
    }

    func clearContentInsets() {
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    // MARK: UIScrollViewDelegate

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setPictoCenter()
    }

    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomEnabled ? imageViewWrapper : nil
    }

}

fileprivate extension UITextView {

    func centerVerticalText() {
        let fitSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fitSize)
        let calculate = (bounds.size.height - size.height * zoomScale) / 2
        let offset = max(1, calculate)
        contentOffset.y = -offset
    }
    
    func centerBottomText(margin: CGFloat) {
        let fitSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fitSize)
        let calculate = (bounds.size.height - size.height * zoomScale)
        let offset = max(1, calculate)
        contentOffset.y = -offset + margin
    }
}

public class CenteredBottomTextView: UITextView {
    public override var contentSize: CGSize {
        didSet {
            setBottomContentInset()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setBottomContentInset()
    }
    
    private func setBottomContentInset() {
        var topCorrection = (bounds.size.height - contentSize.height * zoomScale)
        topCorrection = max(0, topCorrection)
        contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
    }
}

private extension UIResponder {

    private struct Static {
        static weak var responder: UIResponder?
    }

    static func currentFirst() -> UIResponder? {
        Static.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.myTrap), to: nil, from: nil, for: nil)
        return Static.responder
    }

    @objc private func myTrap() {
        Static.responder = self
    }
}
