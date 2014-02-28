class @Relation extends Array
  constructor: (klass, args...) ->
    @klass = klass
    @push.apply(@, args)

  @new: (klass, args...) ->
    new @(klass, args...)

  setLink: (foreign_key, id) ->
    @link = {}
    @link[foreign_key] = id

  link: () ->
    @link

  create: (attr) ->
    attr = _.extend(attr, @link) if @link
    @klass.create(attr)
