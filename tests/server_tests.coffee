# have to destroy all before running server tests, otherwise collection keeps growing!
Tinytest.add "model find", (test) ->
  Recipe.destroyAll()
  test.equal Recipe.count(), 0

Tinytest.add "model find with count", (test) ->
  Recipe.create {name: 'BBQ Ham'}
  Recipe.create {name: 'Meatballs'}
  test.equal Recipe.count(), 2