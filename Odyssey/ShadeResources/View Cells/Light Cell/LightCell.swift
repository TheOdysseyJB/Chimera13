//
//  LightCell.swift
//  Odyssey
//
//  Created by Amy While on 25/11/2020.
//  Copyright © 2020 coolstar. All rights reserved.
//

import UIKit

class LightCell: UITableViewCell {

    @IBOutlet weak var lightEnabled: UIView!
    @IBOutlet weak var lightLabel: UILabel!
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
