class @User extends Minimongoid
  # indicate which collection to use
  @_collection: Meteor.users

  # class methods
  @current: ->
    User.init(Meteor.user()) if Meteor.userId()
  @has_many: [
    {name: 'recipes'}
  ]
  @has_and_belongs_to_many: [
    {name: 'friends', class_name: 'User'}
  ]

  # instance methods 
  friendsWith: (user_id) ->
    _.contains @friend_ids, user_id
  myFriend: ->
    User.current().friendsWith(@id)
  email: ->
    if (@emails and @emails.length) then @emails[0].address else ''

class @Recipe extends Minimongoid
  @_collection: new Meteor.Collection('recipes')
  @belongs_to: [
    {name: 'user'}
  ]
  @embeds_many: [
    {name: 'ingredients'}
  ]
  @defaults:
    name: ''
    cooking_time: '30 mins'

  spicy: ->
    "That's a spicy #{@name}!"

  myRecipe: ->
    @user_id == Meteor.userId()


class @Ingredient extends Minimongoid
  @embedded_in: 'recipe'

  @defaults:
    quantity: 1

  nice_quantity: ->
    if @quantity == 1 then "#{@quantity} dash" else "#{@quantity} dashes"

  myRecipe: ->
    @recipe.myRecipe()


