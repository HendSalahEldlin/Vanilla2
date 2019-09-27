//
//  MainTVRecipeCell.swift
//  Vanilla
//
//  Created by Hend  on 9/20/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import UIKit
import CoreData

protocol CellActionDelegate {
    func shareARecipe(indexPath: IndexPath)
    func addToFav(indexPath: IndexPath)
}

class MainTVRecipeCell: UITableViewCell {
    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var favBtn: UIButton!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    var delegate: CellActionDelegate?
    var indexPath: IndexPath!
    
    @IBAction func favBtnPressed(_ sender: UIButton) {
        delegate?.addToFav(indexPath: self.indexPath)
    }
    
    @IBAction func shareBtnPressed(_ sender: UIButton) {
        delegate?.shareARecipe(indexPath: self.indexPath)
    }
}

// MARK: - HELPER METHODS
extension MainTVRecipeCell {
    
    func set(withRecipe recipe: Recipe?, withFavRecipe favRecipe: FavRecipe?, indexPath: IndexPath, inFavourite: Bool ) {
        
        self.indexPath = indexPath
        let favouriteImage = inFavourite ? #imageLiteral(resourceName: "redHeart-30x30") :  #imageLiteral(resourceName: "emptyHeart-30x30")
        self.favBtn.setImage(favouriteImage, for: .normal)
        
        self.titleLabel.text = recipe != nil ? recipe?.title : favRecipe!.title
        
        if let imageData = recipe != nil ? MainTVRecipeCell.getImage(forRecipe: recipe!) : favRecipe!.image {
            let image = UIImage(data: imageData)
            self.myImageView.image = image!
        }
    }
    
    static func getImage(forRecipe recipe: Recipe) -> Data? {
        guard let image = recipe.image else { return nil}
        var url = URL(string: image)
        if !UIApplication.shared.canOpenURL(url!){
            url = URL(string: Spoonacular.Constants.baseUri + image)!
        }
        let data = try? Data(contentsOf: url!)
        return data
    }
}
