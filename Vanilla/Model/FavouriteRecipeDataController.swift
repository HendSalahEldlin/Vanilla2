//
//  FavouriteRecipeDataController.swift
//  Vanilla
//
//  Created by Hend on 9/27/19.
//  Copyright © 2019 Hend . All rights reserved.
//

import Foundation
import CoreData

class FavouriteRecipeDataController {
    
    static let shared = FavouriteRecipeDataController()
    private static var dataController: DataController!
    static var favouriteRecipes: [FavRecipe]!
    
    private init() {
        FavouriteRecipeDataController.dataController = DataController(modelName: "Vanilla")
        FavouriteRecipeDataController.dataController.load()
        FavouriteRecipeDataController.favouriteRecipes = [FavRecipe]()
    }
    
    func getFavouriteRecipe(withId id: String) -> FavRecipe? {
        let recipeFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavRecipe")
        let recipeSortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        recipeFetchRequest.sortDescriptors = [recipeSortDescriptor]
        recipeFetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        if let favourites = try? FavouriteRecipeDataController.dataController.viewContext.fetch(recipeFetchRequest) as? [FavRecipe] {
            return favourites.first
        }
        return nil
    }
    
    func isRecipeInFavourite(withRecipeId id: String) -> Bool {
        let recipeFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavRecipe")
        let recipeSortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        recipeFetchRequest.sortDescriptors = [recipeSortDescriptor]
        recipeFetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        if let favourites = try? FavouriteRecipeDataController.dataController.viewContext.fetch(recipeFetchRequest) as? [FavRecipe] {
            return !(favourites.isEmpty)
        }
        return false
    }
    
    func saveRecipe(recipeJSON: [String:AnyObject] ){
        let favRecipe = FavRecipe(context: FavouriteRecipeDataController.dataController.viewContext)
        favRecipe.id = String(describing: recipeJSON[Spoonacular.JSONResponseKeys.id]!)
        favRecipe.title = recipeJSON[Spoonacular.JSONResponseKeys.title] as? String
        favRecipe.minutes = Int16(recipeJSON[Spoonacular.JSONResponseKeys.readyInMinutes] as! Int)
        favRecipe.servings = Int16(recipeJSON[Spoonacular.JSONResponseKeys.servings] as! Int)
        favRecipe.url = recipeJSON[Spoonacular.JSONResponseKeys.sourceUrl] as? String ?? ""
        favRecipe.creationDate = Date()
        favRecipe.image = try? Data(contentsOf: URL(string: (recipeJSON[Spoonacular.JSONResponseKeys.image] as? String)!)!)
        
        guard let ingredientsArr = recipeJSON[Spoonacular.JSONResponseKeys.ingredients] as? [[String:AnyObject]] else { return }
        for ingredient in ingredientsArr{
            let myIngredient = Ingredient(context: FavouriteRecipeDataController.dataController.viewContext)
            myIngredient.recipeId = favRecipe.id
            myIngredient.original = ingredient["original"] as? String ?? ""
        }
        
        guard let instructionsArr = recipeJSON[Spoonacular.JSONResponseKeys.instructions] as? [[String:AnyObject]] else { return }
        for instruction in instructionsArr{
            let steps = instruction["steps"] as! [[String : AnyObject]]
            for step in steps{
                let myStep = Instruction(context: FavouriteRecipeDataController.dataController.viewContext)
                myStep.recipeId = favRecipe.id
                myStep.step = step["step"] as? String ?? ""
            }
        }
        FavouriteRecipeDataController.dataController.hasChanges()
        FavouriteRecipeDataController.updateRecipes()
    }
    
    func deleteRecipe(withRecipeId id: String) {
        if let recipeToDelete = getFavouriteRecipe(withId: id) {
            FavouriteRecipeDataController.dataController.viewContext.delete(recipeToDelete)
            FavouriteRecipeDataController.dataController.hasChanges()
            FavouriteRecipeDataController.updateRecipes()
        }
    }
    
    private static func updateRecipes() {
        let recipeFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FavRecipe")
        let recipeSortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        recipeFetchRequest.sortDescriptors = [recipeSortDescriptor]
        if let recipes = try? dataController.viewContext.fetch(recipeFetchRequest) as? [FavRecipe] {
            FavouriteRecipeDataController.favouriteRecipes = recipes
        }
    }
    
    func getRecipeIngredients(withId recipeId: String) -> [Ingredient]? {
        let ingredientsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Ingredient")
        let ingredientsSortDescriptor = NSSortDescriptor(key: "recipeId", ascending: false)
        ingredientsFetchRequest.sortDescriptors = [ingredientsSortDescriptor]
        ingredientsFetchRequest.predicate = NSPredicate(format: "recipeId == %@", recipeId)
        
        if let ingredients = try? FavouriteRecipeDataController.dataController.viewContext.fetch(ingredientsFetchRequest) as? [Ingredient] {
            return ingredients
        }
        return nil
    }
    
    func getRecipeInstructions(withId recipeId: String) -> [Instruction]? {
        let instructionsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Instruction")
        let instructionsSortDescriptor = NSSortDescriptor(key: "recipeId", ascending: false)
        instructionsFetchRequest.sortDescriptors = [instructionsSortDescriptor]
        instructionsFetchRequest.predicate = NSPredicate(format: "recipeId == %@", recipeId)
        
        if let instructions = try? FavouriteRecipeDataController.dataController.viewContext.fetch(instructionsFetchRequest) as? [Instruction] {
            return instructions
        }
        return nil
    }
}
