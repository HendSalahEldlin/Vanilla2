//
//  Extentions.swift
//  Vanilla
//
//  Created by Hend  on 9/27/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import UIKit

extension UIImage {
    func getImageRatio() -> CGFloat {
        let imageRatio = CGFloat(self.size.width / self.size.height)
        return imageRatio
    }
}
