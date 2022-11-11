//
//  ImageSlideshowTextOverlay.swift
//  
//
//  Created by Kondamon on 09.11.22.
//

import UIKit

class ImageSlideshowTextOverlay: UIView {
    
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
        textView.layer.applyDarker2()
        
        return textView
    }()
    
    /// To be able to better see text
    private(set) lazy var imageOverlayGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, // top
                           UIColor.black.withAlphaComponent(0.6).cgColor]
        
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.isHidden = true
        return gradient
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(imageOverlayGradientLayer)
        self.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageOverlayGradientLayer.isHidden = label.text.isEmpty
        imageOverlayGradientLayer.frame = CGRect(x: 0,
                                                 y: (bounds.maxY - bounds.minY) / 2,
                                                 width: bounds.width,
                                                 height: bounds.height / 2)
        if #available(iOS 13.0, *) {
            updateFontsAndMargins()
        }
    }
    
    @available(iOS 13.0, *)
    private func updateFontsAndMargins() {
        let generator = ItemSettingGenerator()
        let settings = generator.getSettings(bounds.size,
                                             mode: .element)
        label.font = settings.titleFont
        // label.centerBottomText(margin: settings.margins.bottom)
        label.textContainerInset.left = settings.margins.left
        label.textContainerInset.right = settings.margins.right
    }
    
    func updateView(text: String?) {
        label.text = text
    }
}

extension CALayer {
    
    public struct Settings {
        let xPos: CGFloat
        let yPos: CGFloat
        let alpha: Float
        let blur: CGFloat
        let spread: CGFloat
        let color: UIColor
        
        public init(xPos: CGFloat, yPos: CGFloat, alpha: Float, blur: CGFloat, spread: CGFloat, color: UIColor) {
            self.xPos = xPos
            self.yPos = yPos
            self.alpha = alpha
            self.blur = blur
            self.spread = spread
            self.color = color
        }
    }
    
    func applyDarker2() {
        let settings = Settings(xPos: 2.0, yPos: 2.0, alpha: 0.8, blur: 9, spread: 0, color: .black)
        applyShadow(settings)
    }
    
    /// Add a H21 SketchShadowType to a view's layer. Default shadow is applied without any parameters.
    /// - Parameters:
    ///   - type: Shadow types
    ///   - path: Path for shadow
    ///   - isDarkModeEndabled: When set to true, shadow is cleared. You have to manually set dark mode enabled,
    ///   since this can not always be correctly detected in CALayer.
    func applyShadow(_ settings: Settings, path: UIBezierPath? = nil, isDarkModeEndabled: Bool = false) {
        guard !isDarkModeEndabled else {
            clearShadow()
            return
        }
        applySketchShadow(color: settings.color,
                          alpha: settings.alpha,
                          x: settings.xPos,
                          y: settings.yPos,
                          blur: settings.blur,
                          spread: settings.spread,
                          path: path)
    }
    
    // swiftlint:disable identifier_name function_parameter_count
    /// Add shadow to a view's layer through parameters from Sketch app. Source
    /// from [Stackoverflow](https://stackoverflow.com/a/54372639/6702020)
    func applySketchShadow(color: UIColor,
                           alpha: Float,
                           x: CGFloat,
                           y: CGFloat,
                           blur: CGFloat,
                           spread: CGFloat,
                           path: UIBezierPath? = nil) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowRadius = blur / 2
        if let path = path {
            if spread == 0 {
                shadowOffset = CGSize(width: x, height: y)
            } else {
                guard path.bounds.width != 0, path.bounds.height != 0 else { return }
                let scaleX = (path.bounds.width + (spread * 2)) / path.bounds.width
                let scaleY = (path.bounds.height + (spread * 2)) / path.bounds.height
                
                path.apply(CGAffineTransform(translationX: x + -spread, y: y + -spread).scaledBy(x: scaleX, y: scaleY))
                shadowPath = path.cgPath
            }
        } else {
            shadowOffset = CGSize(width: x, height: y)
            if spread == 0 {
                shadowPath = nil
            } else {
                let dx = -spread
                let rect = bounds.insetBy(dx: dx, dy: dx)
                shadowPath = UIBezierPath(rect: rect).cgPath
            }
        }
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }
    
    /// Removes all shadows
    func clearShadow() {
        applySketchShadow(color: .clear, alpha: 0, x: 0, y: 0, blur: 0, spread: 0)
    }
}
