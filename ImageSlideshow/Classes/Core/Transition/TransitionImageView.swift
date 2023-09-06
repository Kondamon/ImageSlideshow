//
//  TransitionImageView.swift
//  
//
//  Created by Kondamon on 09.11.22.
//

import UIKit

/// ImageView with text and overlay to better see text used for transition animation
class TransitionImageView: UIImageView {
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        contentMode = UIViewContentMode.scaleAspectFill
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
