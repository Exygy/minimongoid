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

Tinytest.add "can have one to one association", (test) ->
  Recipe.create {name: 'Smoothie'}
  recipe = Recipe.first {name: 'Smoothie'}
  Instruction.create {recipe_id: recipe._id, text: 'Blend everything.'}
  instruction = Instruction.first({text: 'Blend everything.'})

  test.equal recipe.instruction().text, 'Blend everything.'
  test.equal instruction.recipe().name, 'Smoothie'

Tinytest.add "can have model validation", (test) ->
  r = Recipe.create {name: ''}
  test.equal r.errors.length, 1

  r = Recipe.create {name: 'named'}
  test.equal 1, Recipe.count {name: 'named'}
  test.equal r.errors.length > 0, false
