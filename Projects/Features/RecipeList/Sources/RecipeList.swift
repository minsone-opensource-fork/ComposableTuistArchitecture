import CasePaths
import Combine
import ComposableArchitecture
import SwiftUI
import ComposableTuistArchitectureSupport
import AddRecipe

public func makeRecipeListView(store: Store<RecipeListFeatureState, RecipeListFeatureAction>) -> some View {
    RecipeListView(store: store)
}

struct RecipeListView: View {
    struct State: Equatable {
        var recipes: [Recipe]
        var isActivityIndicatorHidden: Bool
        var isAddRecipeNavigationActive: Bool
    }
    
    enum Action {
        case recipes
        case isShowingAddRecipeChanged(Bool)
    }
    
    let store: Store<RecipeListFeatureState, RecipeListFeatureAction>
    
    var body: some View {
        WithViewStore(
            self.store
                .scope(state: \.recipeList, action: RecipeListFeatureAction.recipeList)
                .scope(state: State.init, action: RecipeListAction.init)
        ) { viewStore in
            NavigationView {
                VStack {
                    List {
                        ForEach(viewStore.recipes) { recipe in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                Text("Duration: " + String(recipe.duration))
                            }
                        }
                    }
                    // NavigationLink does not work as a trailing navigationButton
                    NavigationLink(
                        destination: makeAddRecipeView(store: self.store.scope(state: \.addRecipeFeatureState, action: RecipeListFeatureAction.addRecipe)),
                        isActive: viewStore.binding(get: \.isAddRecipeNavigationActive, send: Action.isShowingAddRecipeChanged)
                    ) {
                        EmptyView()
                    }
                }
                .onAppear { viewStore.send(.recipes) }
                .navigationBarTitle("Recipes")
                .navigationBarItems(
                    // NavigationLink does not work as a trailing navigationButton
                    trailing: Button(
                        action: {
                            viewStore.send(
                                .isShowingAddRecipeChanged(!viewStore.isAddRecipeNavigationActive)
                            )
                        }
                    ) {
                        Image(uiImage: Asset.icAdd.image)
                    }
                )
            }
            if viewStore.isActivityIndicatorHidden {
                ActivityIndicator()
            }
        }
    }
}

extension RecipeListView.State {
    init(recipeListState: RecipeListState) {
        recipes = recipeListState.recipes
        isActivityIndicatorHidden = recipeListState.isLoadingRecipes
        isAddRecipeNavigationActive = recipeListState.isShowingAddRecipe
    }
}

extension RecipeListAction {
    init(action: RecipeListView.Action) {
        switch action {
        case .recipes:
            self = .recipes
        case let .isShowingAddRecipeChanged(isShowingAddRecipe):
            self = .isShowingAddRecipeChanged(isShowingAddRecipe)
        }
    }
}

struct RecipeList_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView(
            store: Store<RecipeListFeatureState, RecipeListFeatureAction>(
                initialState: RecipeListFeatureState(
                    recipes: [
                        Recipe(id: "a", name: "Spaghetti", description: "", ingredients: [], duration: 20, score: 2, info: "")
                    ],
                    isLoadingRecipes: false
                ),
                reducer: recipeListFeatureReducer,
                environment: RecipeListFeatureEnvironment(
                    cookbookClient: .mock(
                        recipes: {
                            Effect(
                                value: [
                                    Recipe(id: "a", name: "Spaghetti", description: "", ingredients: ["Banana"], duration: 20, score: 2, info: "")
                                ]
                            )
                        }
                    ),
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                )
            )
        )
    }
}
