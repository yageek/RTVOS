//
//  VideoCell.swift
//  RTVOS
//
//  Created by Yannick Heinrich on 08.03.18.
//  Copyright © 2018 yageek. All rights reserved.
//

import UIKit

final class VideoCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCell"

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!
    
}
