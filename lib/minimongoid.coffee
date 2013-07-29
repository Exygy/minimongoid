global = @

class @Minimongoid
  # --- instance vars
  id: undefined
  # attr: {}

  # --- instance methods 
  constructor: (attr = {}, parent = null) ->
    if attr._id
      if @constructor._object_id
        @id = attr._id._str
      else
        @id = attr._id

    # initialize relation arrays to be an empty array, if they don't exist 
    for habtm in @constructor.has_and_belongs_to_many
      # e.g. matchup.game_ids = []
      identifier = "#{_.singularize(habtm.name)}_ids"
      @[identifier] ||= []
    # initialize relation arrays to be an empty array, if they don't exist 
    for embeds_many in @constructor.embeds_many
      @[embeds_many.name] ||= []

    if @constructor.embedded_in and parent
      @[@constructor.embedded_in] = parent

    for name, value of attr
      continue if name.match(/^_id/)
      if name.match(/_id$/) and (value instanceof Meteor.Collection.ObjectID)
        @[name] = value._str
      else if _.findWhere(@constructor.embeds_many, {name: name})
        # initialize a model with the appropriate attributes 
        # also pass "self" along as the parent model
        @[name] = global[_.classify(_.singularize(name))].modelize(value, @)
      else
        @[name] = value

    for attr, val of @constructor.defaults
      @[attr] = val if typeof @[attr] is 'undefined'



  # alias to @related
  r: (relation) ->
    @related(relation)

  # look up related models 
  related: (relation, options = {}) ->
    # self = @
    # is it a belongs_to? 
    for belongs_to in @constructor.belongs_to
      if relation == belongs_to.name
        identifier = "#{belongs_to.name}_id"
        # set up default class name, e.g. "belongs_to: user" ==> 'User'
        unless belongs_to.class_name
          belongs_to.class_name = _.titleize belongs_to.name
        # if we have a relation_id 
        if @[identifier]
          return global[belongs_to.class_name].find @[identifier], options
        else
          return false
    # is it a has many?
    for has_many in @constructor.has_many
      if relation == has_many.name
        selector = {}
        unless foreign_key = has_many.foreign_key
          # can't use @constructor.name in production because it's been minified to "n"
          # foreign_key = "#{_.singularize(@constructor.name.toLowerCase())}_id"
          return []
        if @constructor._object_id
          selector[foreign_key] = new Meteor.Collection.ObjectID @id
        else
          selector[foreign_key] = @id
        # set up default class name, e.g. "has_many: users" ==> 'User'
        unless has_many.class_name
          has_many.class_name = _.titleize _.singularize(has_many.name)
        # e.g. where {user_id: @id}
        return global[has_many.class_name].where selector, options
    # is it a has many? (same as HABTM)
    for habtm in @constructor.has_and_belongs_to_many
      if relation == habtm.name
        identifier = "#{_.singularize(habtm.name)}_ids"
        # set up default class name, e.g. "habtm: users" ==> 'User'
        unless habtm.class_name
          habtm.class_name = _.titleize _.singularize(habtm.name)
        if @[identifier] and @[identifier].length
          return global[habtm.class_name].where {_id: {$in: @[identifier]}}, options
        else
          return []


  isPersisted: -> @id?

  errors: (val) ->
    if typeof val != 'undefined'
      @constructor.errors = val
    else
      @constructor.errors


  error: (field, message) ->
    @constructor.errors ||= []
    obj = {}
    obj[field] = message
    @constructor.errors.push obj

  isValid: (attr = {}) -> 
    @validate()
    not @errors()

  # nothing by default
  validate: ->
    # if blah then @errors.blah = 'bloo' else @errors = null
    true

  save: (attr = {}) ->
    # reset errors before running isValid()
    @errors(false)

    for k,v of attr
      @[k] = v
    return false unless @isValid()

    # attr['_type'] = @constructor._type if @constructor._type?
    
    if @isPersisted()
      @constructor._collection.update @id, { $set: attr }
    else
      @id = @constructor._collection.insert attr
    
    if @constructor.after_save
      @constructor.after_save(@)

    this

  update: (attr) ->
    @save(attr)

  # push to mongo array field
  push: (data) ->
    # for name, value of data 
    #   # update locally 
    #   @[name].push value
    # and push to DB    

    # addToSet to ensure uniqueness -- can't think of if/when we WOULDN'T want that??
    @constructor._collection.update @id, {$addToSet: data}

  # pull from mongo array field
  pull: (data) ->
    @constructor._collection.update @id, {$pull: data}

  del: (field) ->
    unset = {}
    unset[field] = ""
    @constructor._collection.update @id, {$unset: unset}

  destroy: ->
    if @isPersisted()
      @constructor._collection.remove @id
      @id = null

  # --- class variables
  @_object_id: false
  @_collection: undefined
  @_type: undefined

  @defaults: []

  @errors = false
  @belongs_to: []
  @has_many: []
  @has_and_belongs_to_many: []

  @embedded_in: null
  @embeds_many: []

  # @after_save: null
  # @before_save: null
  # @before_create: null
  # @after_create: null


  # --- class methods
  @init: (attr, parent = null) ->
    new @(attr, parent)

  @create: (attr) ->
    attr.createdAt = new Date().getTime()
    attr = @before_create(attr) if @before_create
    doc = @init(attr)
    doc = doc.save(attr)
    if doc and @after_create
      @after_create(doc)
    else
      doc

  # find + modelize
  @where: (selector = {}, options = {}) ->
    @modelize @find(selector, options)

  @first: (selector = {}, options = {}) ->
    if doc = @_collection.findOne(selector)
      @init doc

  @last: (selector = {}, options = {}) ->
    if doc = @_collection.findOne(selector, sort: createdAt: -1)
      @init doc

  @all: (options) ->
    @where({}, options)

  # this doesn't perform a fetch, just generates a collection cursor
  @find: (selector = {}, options = {}) ->
    # unless you just pass an id, in which case it *does* fetch the first
    unless typeof selector == 'object'
      if @_object_id
        selector = new Meteor.Collection.ObjectID selector
      @first {_id: selector}, options
    else if selector instanceof Meteor.Collection.ObjectID
      @first {_id: selector}, options
    else
      # handle objectIDs -- these would come from an external database entry e.g. Rails
      if @_object_id
        if selector and selector._id
          if typeof selector._id is 'string'
            selector._id = new Meteor.Collection.ObjectID selector._id
          else if selector._id['$in']
            # _.map(game_ids, function(x) { return new Meteor.Collection.ObjectID(x) })
            selector._id['$in'] = _.map_object_id selector._id['$in']
        if selector and selector._ids 
          selector._ids = _.map(selector._ids, (id) -> new Meteor.Collection.ObjectID id)
      @_collection.find selector, options


  @count: (selector = {}, options = {}) ->
    @find(selector, options).count()

  @destroyAll: (selector = {}) ->
    @_collection.remove(selector)


  # run a model init on all items in the collection 
  @modelize: (cursor, parent = null) ->
    self = @
    cursor.map (i) -> self.init(i, parent)

