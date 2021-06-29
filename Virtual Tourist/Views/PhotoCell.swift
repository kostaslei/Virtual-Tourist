//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 29/04/2021.
//

import Foundation
import UIKit
// Cell imageView
class PhotoCell: UICollectionViewCell{
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
    }
}
