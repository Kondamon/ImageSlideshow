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
