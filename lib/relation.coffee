class @Relation extends Array
  constructor: (klass, args...) ->
    @klass = klass
    @push.apply(@, args)

  @new: (klass, args...) ->
    new @(klass, args...)

  create: (attr) ->
    @klass.create(attr)
