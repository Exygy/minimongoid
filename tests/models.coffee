class @Recipe extends Minimongoid
  @_collection: new Meteor.Collection('recipes')
  @belongs_to: [
    {name: 'user'}
  ]
  @has_and_belongs_to_many: [
    {name: 'bookmarkers', class_name: 'User'}
  ]
  @embeds_many: [
    {name: 'ingredients'}
  ]
  validate: ->
    unless @name and @name.length > 2
      @error 'name', 'Must have a name of at least 2 characters.'

class @Ingredient extends Minimongoid
  @embedded_in: 'recipe'
  # lets give it an instance method
  spicy_name: ->
    "spicy #{@name}"
