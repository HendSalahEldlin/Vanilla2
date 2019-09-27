//
//  FavouritesViewController.swift
//  Vanilla
//
//  Created by Hend  on 9/27/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import UIKit

class FavouritesViewController: UIViewController {

    // MARK: - IBOUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - PROPRITIES
    var recipeDataController = FavouriteRecipeDataController.shared
    
    // MARK: - VIEWCONTROLLER LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
    }

}

// MARK: - HELPER METHODS
extension FavouritesViewController{
    
    func registerTableViewCells() {
        self.tableView.register(UINib(nibName: "MainTVRecipeCell",
                                      bundle: nil), forCellReuseIdentifier: "RecipeCell")
    }
    
    func diplayDetailsVC(withRecipeId id: String) {
        let detailsVC = self.storyboard?.instantiateViewController(withIdentifier: "DetailsViewController") as! DetailsViewController
        detailsVC.recipeId = id
        self.navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func deleteRecipeFromFavourite(withId id: String) {
        DispatchQueue.main.async {
            self.recipeDataController.deleteRecipe(withRecipeId: id)
            self.tableView.reloadData()
        }
    }
    
    //presentActivityVC to share recipe link
    func presentActivityVC(sourceUrl: String) {
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [sourceUrl as Any], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}

// MARK: - TABLE VIEW DELEGATE & DATA SOURCE
extension FavouritesViewController: UITableViewDelegate, UITableViewDataSource {
    
    // table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FavouriteRecipeDataController.favouriteRecipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell")! as! MainTVRecipeCell
        
        let favRecipe = FavouriteRecipeDataController.favouriteRecipes[indexPath.row]
        let inFavourite = recipeDataController.isRecipeInFavourite(withRecipeId: favRecipe.id!)
        
        cell.set(withRecipe: nil, withFavRecipe: favRecipe, indexPath: indexPath, inFavourite: inFavourite)
        cell.delegate = self
        
        return cell
    }
    
    // table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let recipeId = FavouriteRecipeDataController.favouriteRecipes[indexPath.row].id {
            diplayDetailsVC(withRecipeId: recipeId)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let recipe = FavouriteRecipeDataController.favouriteRecipes[indexPath.row]
        guard let imageData = recipe.image else { return 186.5 }
        let imageRatio = UIImage(data: imageData)!.getImageRatio()
        return tableView.frame.width / imageRatio
    }
}

// MARK: - CELL ACTION DELEGATE
extension FavouritesViewController: CellActionDelegate {
    
    func shareARecipe(indexPath: IndexPath) {
        let recipe = FavouriteRecipeDataController.favouriteRecipes[indexPath.row]
        presentActivityVC(sourceUrl: recipe.url!)
    }
    
    func addToFav(indexPath: IndexPath) {
        
    }
}

