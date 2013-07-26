class @User extends Minimongoid
  # indicate which collection to use
  @_collection: Meteor.users

  # class methods
  @current: ->
    User.init(Meteor.user()) if Meteor.userId()
  @has_many: [
    {name: 'recipes', foreign_key: 'user_id'}
  ]
  @has_and_belongs_to_many: [
    {name: 'friends', class_name: 'User'}
  ]

  # instance methods 
  # return true if user is friends with User where id==user_id
  friendsWith: (user_id) ->
    _.contains @friend_ids, user_id
  # return true if user is friends with the current logged in user
  myFriend: ->
    User.current().friendsWith(@id)
  # grab the first email off the emails array
  email: ->
    if (@emails and @emails.length) then @emails[0].address else ''

class @Recipe extends Minimongoid
  # indicate which collection to use
  @_collection: new Meteor.Collection('recipes')

  # model relations
  @belongs_to: [
    {name: 'user'}
  ]
  @embeds_many: [
    {name: 'ingredients'}
  ]

  # model defaults
  @defaults:
    name: ''
    cooking_time: '30 mins'

  # titleize the name before creation   
  @before_create: (attr) ->
    attr.name = _.titleize(attr.name)
    attr

  # class methods
  # Find me all recipes with an ingredient that starts with "zesty"
  @zesty: ->
    @where({'ingredients.name': /^zesty/i})

  @error_message: ->
    msg = ''
    for i in @errors
      for key,value of i
        msg += "<strong>#{key}:</strong> #{value}"
    msg

  # Add some validation parameters. As long as the @error() method is triggered, then validation will fail
  validate: ->
    unless @name and @name.length > 3
      @error('name', 'Recipe name is required and should be longer than 3 letters.')

  # instance methods
  spicy: ->
    "That's a spicy #{@name}!"

  # is this one of my personal creations? T/F
  myRecipe: ->
    @user_id == Meteor.userId()

  creator_name: ->
    @r('user').username


class @Ingredient extends Minimongoid
  @embedded_in: 'recipe'

  @defaults:
    quantity: 1

  nice_quantity: ->
    if @quantity == 1 then "#{@quantity} dash" else "#{@quantity} dashes"

  myRecipe: ->
    @recipe.myRecipe()


