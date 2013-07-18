Tinytest.add "can create a basic model", (test) ->
  Recipe.create {name: 'Apple Pie'}
  recipe = Recipe.first {name: 'Apple Pie'} 
  test.equal recipe.name, 'Apple Pie'

Tinytest.add "can have embedded models", (test) ->
  Recipe.create {name: 'Chicken Parmesan', ingredients: [{name: 'chicken'}, {name: 'parmesan'}]}
  recipe = Recipe.first {name: 'Chicken Parmesan'}
  ingredient = recipe.ingredients[0]
  test.equal ingredient.name, 'chicken'
  test.equal ingredient.spicy_name(), 'spicy chicken'

Tinytest.add "can have model validation", (test) ->
  r = Recipe.create {name: ''}
  test.equal r, false
  test.equal Recipe.errors.length, 1

  r = Recipe.create {name: 'named'}
  test.equal 1, Recipe.count {name: 'named'}
  test.equal Recipe.errors, false
