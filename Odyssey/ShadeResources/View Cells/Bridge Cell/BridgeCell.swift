//
//  BridgeCell.swift
//  Shade
//
//  Created by Amy While on 24/10/2020.
//

import UIKit

class BridgeCell: UITableViewCell {
    
    @IBOutlet weak var hueImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBInspectable weak var minHeight: NSNumber! = 50
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        guard let minHeight = minHeight else { return size }
        return CGSize(width: size.width, height: max(size.height, (minHeight as! CGFloat)))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
}
