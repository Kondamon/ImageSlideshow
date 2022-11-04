//
//  ItemSettingGenerator.swift
//  
//
//  Created by Kondamon on 02.08.22.
//

import UIKit

/// Returns settings for visionElements depending on frame size and mode
@available(iOS 13.0, *)
struct ItemSettingGenerator {
    
    enum Mode {
        case element
        /// VisionElement over full scren (e.g. Video)
        case fullScreen
    }
    
    struct Setting {
        var titleFont: UIFont
        var subtitleFont: UIFont
        var margins: UIEdgeInsets
        var numberOfLines: Int = 0
        var textAlignment: NSTextAlignment = .center
        var titleSubtitleSpacing: CGFloat = 0
    }
    
    //swiftlint:disable function_body_length
    func getSettings(_ visionElementSize: CGSize, mode: Mode) -> Setting {
        let hasIpadScreen = visionElementSize.width > 500
        switch mode {
        case .fullScreen:
            return Setting(titleFont: UIFont.scaled(sfPro: .xlargeTitle, .bold),
                           subtitleFont: UIFont.scaled(sfPro: .xlargeTitle, .bold),
                           margins: UIEdgeInsets(top: 30, left: 30, bottom: 35, right: 30),
                           numberOfLines: 3,
                           textAlignment: .center)
        case .element:
            return Setting(titleFont: UIFont.scaled(sfPro: hasIpadScreen ? .title1 : .title3, .medium),
                           subtitleFont: UIFont.scaled(sfPro: hasIpadScreen ? .title1 : .title3, .medium),
                           margins: hasIpadScreen ? UIEdgeInsets(top: 30, left: 30, bottom: 25, right: 30) :
                            UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15),
                           numberOfLines: 0,
                           textAlignment: .center,
                           titleSubtitleSpacing: 0)
           
        }
    }
}
@available(iOS 13.0, *)
extension UIFont {
    // MARK: - Scaled SFPro Font
    
    ///  Creates a scaled SanFrancisco Pro with selected style and weight.
    ///
    /// - Returns: A SanFrancisco Pro `UIFont` that has been
    ///   scaled for the users currently selected preferred
    ///   text size.
    ///
    
    class func scaled(sfPro style: UIFont.TextStyle, _ weight: UIFont.Weight = .regular,
                      design: UIFontDescriptor.SystemDesign = .default, maximumPointSize: CGFloat? = nil) -> UIFont {
        let size = getSize(style: style)
        return makeSfProFont(style: style, size: size, weight: weight, design: design, maximumPointSize: maximumPointSize)
    }
    
    /// Returns a SanFranciscoPro font with selected styles and weight
    private class func makeSfProFont(style: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight,
                                     design: UIFontDescriptor.SystemDesign = .default, maximumPointSize: CGFloat? = nil) -> UIFont {
        
        // default font size is within content size category large
        let preferredDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: .init(preferredContentSizeCategory: .large))
        let desc = preferredDescriptor.withDesign(design) ?? preferredDescriptor
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        let fontMetrics = UIFontMetrics(forTextStyle: style)
        
        let maximumSize = maximumPointSize ?? desc.pointSize + 3 // limit size to prevent ugly display issues
        return fontMetrics.scaledFont(for: font, maximumPointSize: maximumSize)
    }
    
    private class func getSize(style: UIFont.TextStyle) -> CGFloat {
        switch style {
        case .caption2:
            return 11
        case .caption1:
            return 12
        case .footnote:
            return 13
        case .subheadline:
            return 15
        case .callout:
            return 16
        case .body:
            return 17
        case .headline:
            return 17
        case .title3:
            return 20
        case .title2:
            return 22
        case .title1:
            return 28
        case .largeTitle:
            return 34
        case .xlargeTitle:
            return 41
        default:
            return 17
        }
    }
}
extension UIFont.TextStyle {
    
    static var xlargeTitle: UIFont.TextStyle {
        .init(rawValue: "500")
    }
}
