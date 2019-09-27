//
//  RefactoredDetailsViewController.swift
//  Vanilla
//
//  Created by Hend  on 9/27/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {

    //MARK: - OUTLETS
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak internal var timeLabel: UILabel!
    @IBOutlet weak internal var servingsLabel: UILabel!
    @IBOutlet weak internal var favBtn: UIButton!
    @IBOutlet weak var ingredientsTV: UITableView!
    @IBOutlet weak var ingredientsHC: NSLayoutConstraint!
    @IBOutlet weak var instruncionsTV: UITableView!
    @IBOutlet weak var instruncionsHC: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - PROPERTIES
    var recipeId : String?
    var recipe : Recipe?
    var recipeIndex : Int?
    var url : String?
    var recipeDataController = FavouriteRecipeDataController.shared
    var favRecipe : FavRecipe?
    var ingredients : [Ingredient]?
    var instructions : [Instruction]?
    
    // MARK: - VIEWCONTROLLER LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        fillViewControlls()
    }
    
    // MARK: - ACTIONS
    @IBAction func shareBtnPressed(_ sender: UIButton) {
        if self.favRecipe?.url != nil{
            presentActivityVC(sourceUrl: favRecipe!.url!)
        }else{
            Spoonacular.sharedInstance().getRecipeLink(recipeId: recipeId!)
            {(SourceUrl, error) in
                if error == nil{
                    DispatchQueue.main.async {
                        self.presentActivityVC(sourceUrl: SourceUrl)
                    }
                }else{
                    DispatchQueue.main.async {
                        self.showAlert()
                    }
                }
            }
        }
    }
    
    @IBAction func favBtnPressed(_ sender: UIButton) {
        //if recipeIndex is not nil then it is come from main else from fav
        if favBtn.currentImage == #imageLiteral(resourceName: "emptyHeart-30x30"){
            favBtn.setImage(#imageLiteral(resourceName: "redHeart-30x30"), for: .normal)
            saveRecipeToCoreData()
        }else{
            favBtn.setImage(#imageLiteral(resourceName: "emptyHeart-30x30"), for: .normal)
            recipeDataController.deleteRecipe(withRecipeId: recipeId!)
        }
    }

}

// MARK: - HELPER METHODS
extension DetailsViewController{
    
    private func getRecipeInfoFromServer() {
        activityIndicator.startAnimating()
        if recipe?.ingredients == nil {
            Spoonacular.sharedInstance().getRecipeInformation(recipeId: recipeId!, recipeIndex: recipeIndex!) {(success, error) in
                if success{
                    self.recipe = Spoonacular.sharedInstance().recipes[self.recipeIndex!]
                    DispatchQueue.main.async {
                        self.activityIndicator.startAnimating()
                        self.fillControllsfromRecipe()
                    }
                }
            }
        }
    }
    
    fileprivate func fillControllsfromRecipe() {
        self.titleLabel.text = recipe?.title
        if let imageData = MainTVRecipeCell.getImage(forRecipe: recipe!){
            self.imageView.image = UIImage(data: imageData)
        }
        self.timeLabel.text = "\(recipe?.readyInMinutes!)" + " Mins"
        self.servingsLabel.text =  " serves " + "\(recipe?.servings!)"
        self.favBtn.setImage(#imageLiteral(resourceName: "emptyHeart-30x30"), for: .normal)
        self.url = recipe?.recipeURL!
        ingredientsHC.constant = CGFloat(recipe?.ingredients?.count ?? 0) * ingredientsTV.rowHeight
        instruncionsHC.constant = CGFloat(recipe?.instructions?.count ?? 0) * instruncionsTV.rowHeight
    }
    
    private func fillViewControlls() {
        if let favRecipe = recipeDataController.getFavouriteRecipe(withId: recipeId!){
            self.favRecipe = favRecipe
            self.titleLabel.text = favRecipe.title
            self.imageView.image = UIImage(data: ((favRecipe.image!)))
            self.timeLabel.text = "\(favRecipe.minutes)" + " Mins"
            self.servingsLabel.text =  " serves " + "\(favRecipe.servings)"
            self.favBtn.setImage(#imageLiteral(resourceName: "redHeart-30x30"), for: .normal)
            self.ingredients = recipeDataController.getRecipeIngredients(withId: recipeId!) as! [Ingredient]
            self.instructions = recipeDataController.getRecipeInstructions(withId: recipeId!) as! [Instruction]
            ingredientsHC.constant = CGFloat(self.ingredients?.count ?? 0) * ingredientsTV.rowHeight
            instruncionsHC.constant = CGFloat(self.instructions?.count ?? 0) * instruncionsTV.rowHeight
        }else{
            getRecipeInfoFromServer()
            fillControllsfromRecipe()
        }
    }
    
    
    private func saveRecipeToCoreData(){
        var favRecipe = [String:AnyObject]()
        favRecipe[Spoonacular.JSONResponseKeys.id] = recipeId as AnyObject?
        favRecipe[Spoonacular.JSONResponseKeys.title] = self.titleLabel.text as AnyObject?
        favRecipe[Spoonacular.JSONResponseKeys.readyInMinutes] = self.timeLabel.text?.replacingOccurrences(of: " Mins", with: "") as AnyObject
        favRecipe[Spoonacular.JSONResponseKeys.servings] = self.servingsLabel.text!.replacingOccurrences(of: " serves ", with: "") as AnyObject?
        favRecipe[Spoonacular.JSONResponseKeys.sourceUrl] = self.url as AnyObject?
        favRecipe["creationDate"] = Date() as AnyObject?
        favRecipe[Spoonacular.JSONResponseKeys.image] = self.imageView.image?.pngData() as AnyObject?
        
        var myIngredients = [String]()
        for cell in ingredientsTV.visibleCells{
            myIngredients.append(cell.textLabel!.text!)
        }
        favRecipe[Spoonacular.JSONResponseKeys.ingredients] = myIngredients as AnyObject?
        
        var myInstructions = [String]()
        for cell in instruncionsTV.visibleCells {
            myInstructions.append(cell.textLabel!.text!)
        }
        favRecipe[Spoonacular.JSONResponseKeys.instructions] = myInstructions as AnyObject?
        
        recipeDataController.saveRecipe(recipeJSON: favRecipe)
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
        let alert = UIAlertController(title: "OOPS!",
                                      message: "Something went wrong, Do you prefer to reload Vanilla",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
    }
    
}


// MARK: - TABLE VIEW DELEGATE & DATA SOURCE
extension DetailsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if recipeIndex != nil{
            if tableView == ingredientsTV{
                return recipe?.ingredients?.count ?? 0
            }else{
                return recipe?.instructions?.count ?? 0
            }
        }else{
            if tableView == ingredientsTV{
                return self.ingredients?.count ?? 0
            }else{
                return self.instructions?.count ?? 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if tableView == ingredientsTV{
            cell = tableView.dequeueReusableCell(withIdentifier: "DetailsIngredientsTVCell")!
            cell.textLabel?.text = recipeIndex != nil ? recipe?.ingredients![indexPath.row] :  self.ingredients![indexPath.row].original
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "InstructionsTVCell")!
            cell.textLabel?.text = "\(indexPath.row + 1)) \((recipeIndex != nil ? (recipe?.instructions![indexPath.row]) : self.instructions![indexPath.row].step)! )"
        }
        cell.imageView?.image = #imageLiteral(resourceName: "icons8-filled-circle-30")
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font.withSize(12)
        
        return cell
    }
}
