//
//  TransitionImageView.swift
//  
//
//  Created by Kondamon on 09.11.22.
//

import UIKit

/// ImageView with text and overlay to better see text used for transition animation
class TransitionImageView: UIImageView {
    
    private(set) lazy var textOverlay = ImageSlideshowTextOverlay()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        addSubview(textOverlay)
        contentMode = UIViewContentMode.scaleAspectFill
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView(title: String?) {
        textOverlay.updateView(text: title)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textOverlay.frame = self.bounds
    }
    
    func hideLabel() {
        textOverlay.label.alpha = 0
    }
}
