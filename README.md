minimongoid
===========

Mongoid inspired model architecture for your Meteor apps. 

## CoffeeScript
First things first -- it is highly encouraged to use [CoffeeScript](http://coffeescript.org/) with minimongoid, simply because the class inheritance syntax in CoffeeScript is much cleaner and easier to use. Even if your entire app is written in JavaScript, and only your models are written in CS, that would suit you just fine (the example project is done this way). You can use the converter on the CS homepage if you'd like to see the resulting JS output.

# Usage
Like most things in life, it's always easier to demonstrate by example. You can find a working example project in the /example directory. The below comes from the /lib/models.coffee file in that project. Note that it's probably a good idea to stick models somewhere like /lib so they get loaded first -- and yes, you can use these same models on both client and server!

```coffee
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
```


TODO: Add more explanation...


# Testing
There are some stupid simple tests that you can run:

    mrt test-packages ./

-----
Created by Dave Kaplan, and originally derived from Mario Uher's [minimongoid](https://github.com/haihappen/minimongoid). 