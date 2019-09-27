//
//  MainViewController.swift
//  Vanilla
//
//  Created by Hend on 9/27/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - IBOUTLET
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!

    // MARK: - PROPRITIES
    var recipes: [Recipe]!
    var recipeDataController = FavouriteRecipeDataController.shared
    
    var fromFilter = false
    var searchRecipe: String?
    var searchIngredients: String?
    var searchType: String?
    var searchCuisine: String?
    var searchDiet: String?
    var searchMaxTime: Int?
    
    // MARK: - VIEWCONTROLLER LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setInitialValues()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadingView.isHidden = false
        if fromFilter{
            
        }else{
            getRandomDataFromServer()
        }
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        getRandomDataFromServer()
    }
}

// MARK: - HELPER METHODS
extension MainViewController {
    
    func setInitialValues() {
        recipes = [Recipe]()
        registerTableViewCells()
    }
    
    func getRandomDataFromServer() {
        Spoonacular.sharedInstance().getRecipes { (success, recipes, error) in
            if success, error == nil {
                if let validRecipes = recipes {
                    self.recipes = validRecipes
                    DispatchQueue.main.async {
                        self.loadingView.isHidden = true
                        self.tableView.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.loadingView.isHidden = true
                }
                self.showAlert()
            }
        }
    }
    
    func getsearchedDataFromServer() {
        Spoonacular.sharedInstance().recipesComplexSearch(recipes: searchRecipe!, ingredients: searchIngredients!, type: searchType!, cuisine: searchCuisine!, diet: searchDiet!, maxReadyTime: searchMaxTime!) { (success, recipes, error) in
            if success, error == nil {
                if let validRecipes = recipes {
                    self.recipes = validRecipes
                    DispatchQueue.main.async {
                        self.loadingView.isHidden = true
                        self.tableView.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.loadingView.isHidden = true
                }
                self.showAlert()
            }
        }
    }
    
    func registerTableViewCells() {
        self.tableView.register(UINib(nibName: "MainTVRecipeCell",
                                      bundle: nil), forCellReuseIdentifier: "RecipeCell")
    }
    
    func diplayDetailsVC(withRecipeId id: String, withRecipe recipe : Recipe?) {
        let detailsVC = self.storyboard?.instantiateViewController(withIdentifier: "DetailsViewController") as! DetailsViewController
        detailsVC.recipeId = id
        detailsVC.recipe = recipe
        self.navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    func addRecipeToFavourite(withRecipe recipe: Recipe) {
        self.loadingView.isHidden = false
        Spoonacular.sharedInstance().getRecipeInformation(recipeId: recipe.id) {(recipe, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.recipeDataController.saveRecipe(recipeJSON: recipe)
                    self.loadingView.isHidden = true
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func deleteRecipeFromFavourite(withId id: String) {
        self.loadingView.isHidden = false
        DispatchQueue.main.async {
            self.recipeDataController.deleteRecipe(withRecipeId: id)
            self.loadingView.isHidden = true
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
    
    //show alert on network failture
    func showAlert(){
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            let alert = UIAlertController(title: "OOPS!",
                                          message: "Something went wrong, Do you prefer to reload Vanilla",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - CELL ACTION DELEGATE
extension MainViewController: CellActionDelegate {

    func shareARecipe(indexPath: IndexPath) {
        let recipe = self.recipes[indexPath.row]
        if recipe.recipeURL == nil {
            Spoonacular.sharedInstance().getRecipeLink(recipeId: recipe.id)
            {(SourceUrl, error) in
                if error == nil{
                    self.presentActivityVC(sourceUrl: SourceUrl)
                }else{
                    self.showAlert()
                }
            }
        }else{
            presentActivityVC(sourceUrl: recipe.recipeURL!)
        }
    }

    func addToFav(indexPath: IndexPath) {
        let recipe = recipes[indexPath.row]
        if recipeDataController.isRecipeInFavourite(withRecipeId: recipe.id) {
            deleteRecipeFromFavourite(withId: recipe.id)
        } else {
            addRecipeToFavourite(withRecipe: recipe)
        }
    }
}


// MARK: - TABLE VIEW DELEGATE & DATA SOURCE
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    // table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell")! as! MainTVRecipeCell
        
        let recipe = self.recipes[(indexPath as NSIndexPath).row]
        let inFavourite = recipeDataController.isRecipeInFavourite(withRecipeId: recipe.id)
        
        cell.set(withRecipe: recipe, withFavRecipe: nil, indexPath: indexPath, inFavourite: inFavourite)
        cell.delegate = self
        
        return cell
    }
    
    // table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let recipeId = self.recipes[(indexPath as NSIndexPath).row].id {
            diplayDetailsVC(withRecipeId: recipeId, withRecipe: recipes[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let recipe = recipes[indexPath.row]
        guard let imageData = MainTVRecipeCell.getImage(forRecipe: recipe) else { return 186.5 }
        let imageRatio = UIImage(data: imageData)!.getImageRatio()
        return tableView.frame.width / imageRatio
    }
}

