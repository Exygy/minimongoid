global = @

class @Minimongoid
  # --- instance vars
  id: undefined
  errors: false
  # attr: {}

  # --- instance methods
  constructor: (attr = {}, parent = null, is_new = true) ->
    @__is_new = !!is_new
    if attr._id
      if @constructor._object_id
        @id = attr._id._str
      else
        @id = attr._id
      @_id = @id
    @initAttrsAndRelations(attr, parent)

  # this function sets up all of the attributes to be stored on the model as well as
  # setting up the relation methods
  initAttrsAndRelations: (attr = {}, parent = null) ->
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


    # load in all the passed attrs
    for name, value of attr
      continue if name.match(/^_id/)
      if name.match(/_id$/) and (value instanceof Meteor.Collection.ObjectID)
        @[name] = value._str
      else if (embeds_many = _.findWhere(@constructor.embeds_many, {name: name}))
        # initialize a model with the appropriate attributes
        # also pass "self" along as the parent model
        class_name = embeds_many.class_name || _.classify(_.singularize(name))
        @[name] = global[class_name].modelize(value, @)
      else
        @[name] = value

    # load in defaults
    for own attr, val of @constructor.defaults
      @[attr] = val if typeof @[attr] is 'undefined'


    self = @

    # set up belongs_to methods, e.g. recipe.user()
    for belongs_to in @constructor.belongs_to
      relation = belongs_to.name
      identifier = belongs_to.identifier || "#{relation}_id"
      # set up default class name, e.g. "belongs_to: user" ==> 'User'
      class_name = belongs_to.class_name || _.titleize(relation)

      @[relation] = do(relation, identifier, class_name) ->
        (options = {}) ->
          # if we have a relation_id
          if global[class_name] and self[identifier]
            return global[class_name].find self[identifier], options
          else
            return false


    # set up has_many methods, e.g. user.recipes()
    for has_many in @constructor.has_many
      relation = has_many.name
      selector = {}
      unless foreign_key = has_many.foreign_key
        # can't use @constructor.name in production because it's been minified to "n"
        foreign_key = "#{_.singularize(@constructor.to_s().toLowerCase())}_id"
      if @constructor._object_id
        selector[foreign_key] = new Meteor.Collection.ObjectID @id
      else
        selector[foreign_key] = @id
      # set up default class name, e.g. "has_many: users" ==> 'User'
      class_name = has_many.class_name || _.titleize(_.singularize(relation))
      @[relation] = do(relation, selector, class_name) ->
        (mod_selector = {}, options = {}) ->
          # first consider any passed in selector options
          mod_selector = _.extend mod_selector, selector
          # e.g. where {user_id: @id}
          if global[class_name]
            HasManyRelation.fromRelation(global[class_name].where(mod_selector, options), foreign_key, @id)

    # set up has_one methods, e.g. user.recipes()
    for has_one in @constructor.has_one
      relation = has_one.name
      selector = {}
      unless foreign_key = has_one.foreign_key
        foreign_key = "#{_.singularize(@constructor.to_s().toLowerCase())}_id"
      if @constructor._object_id
        selector[foreign_key] = new Meteor.Collection.ObjectID @id
      else
        selector[foreign_key] = @id
      # set up default class name, e.g. "has_one: user" ==> 'User'
      class_name = has_one.class_name || _.titleize(relation)
      @[relation] = do(relation, selector, class_name) ->
        (mod_selector = {}, options = {}) ->
          # first consider any passed in selector options
          mod_selector = _.extend mod_selector, selector
          # e.g. where {user_id: @id}
          if global[class_name]
            global[class_name].first(mod_selector, options)


    # set up HABTM methods, e.g. user.friends()
    for habtm in @constructor.has_and_belongs_to_many
      relation = habtm.name
      identifier = "#{_.singularize(relation)}_ids"
      # set up default class name, e.g. "habtm: users" ==> 'User'
      class_name = habtm.class_name || _.titleize(_.singularize(relation))
      @[relation] = do(relation, identifier, class_name) ->
        (mod_selector = {}, options = {}) ->
          selector =  {_id: {$in: self[identifier]}}
          # first consider any passed in selector options
          mod_selector = _.extend mod_selector, selector
          instance = global[class_name].init()
          filter = (r) ->
            name = r.class_name || _.titleize(_.singularize(r.name))
            global[name] == this.constructor
          inverse = _.find instance.constructor.has_and_belongs_to_many, filter, @
          inverse_identifier = "#{_.singularize(inverse.name)}_ids"
          if global[class_name] and self[identifier] and self[identifier].length
            relation = global[class_name].where mod_selector, options
            return HasAndBelongsToManyRelation.fromRelation(relation, @, inverse_identifier, identifier, @id)
          else
            return HasAndBelongsToManyRelation.new(@, global[class_name], inverse_identifier, identifier, @id)



  # /--------------------
  # DEPRECATED: r() and related() methods
  #             Also does not support has_one.
  # --------------------

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
          foreign_key = "#{_.singularize(@constructor.to_s().toLowerCase())}_id"
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
    # if we get here, means method not found
    console.warn "Method #{relation} does not exist for #{@constructor.to_s()}."


  # isPersisted: -> @id?

  # -------------------
  # --------------------/


  error: (field, message) ->
    @errors ||= []
    obj = {}
    obj[field] = message
    @errors.push obj

  isValid: (attr = {}) ->
    @validate()
    not @errors

  # nothing by default
  validate: ->
    # if blah then @errors.blah = 'no, bad!' else @errors = false
    true

  is_new: () -> @isNew()
  isNew: () -> @__is_new

  save: (attr = {}, callback = undefined) ->
    # reset errors before running isValid()
    @errors = false

    for k,v of attr
      @[k] = v

    attr = @constructor.before_save(attr) if @constructor.before_save

    return @ if not @isValid()

    # attr['_type'] = @constructor._type if @constructor._type?

    if callback?
      if @isNew()
        @constructor._collection.insert( attr, ((error, result) =>
          unless error?
            @id = @_id = result
            @__is_new = false

            if @constructor.after_save
              @constructor.after_save(@)

          callback(error, result)
        ))
      else
        @constructor._collection.update( @id, { $set: attr }, ((error, result) =>
          unless error?
            if @constructor.after_save
              @constructor.after_save(@)

          callback(error, result)
        ))

      return null

    else
      if @isNew()
        @id = @_id = @constructor._collection.insert( attr )
        @__is_new = false
      else
        @constructor._collection.update( @id, { $set: attr } )

      if @constructor.after_save
        @constructor.after_save(@)

      return @

  update: (attr, callback = undefined) ->
    @save(attr, callback)

  # push to mongo array field
  push: (data) ->
    # TODO: should maybe do something like this; but it should know if we're pushing an embedded model and instantiate it...
    # for name, value of data
    #   # update locally
    #   @[name].push value

    # addToSet to ensure uniqueness -- can't think of if/when we WOULDN'T want that??
    @constructor._collection.update @id, {$addToSet: data}

  # pull from mongo array field
  pull: (data) ->
    @constructor._collection.update @id, {$pull: data}

  del: (field) ->
    unset = {}
    unset[field] = ""
    @constructor._collection.update @id, {$unset: unset}

  destroy: (callback = undefined) ->
    if @id?
      @constructor._collection.remove( @id, callback )
      @id = @_id = null

  reload: ->
    if @id?
      @constructor.find(@id)

  # --- class variables
  @_object_id: false
  @_collection: undefined
  @_type: undefined
  @_debug: false

  @defaults: []

  @belongs_to: []
  @has_many: []
  @has_one: []
  @has_and_belongs_to_many: []

  @embedded_in: null
  @embeds_many: []

  # @after_save: null
  # @before_save: null
  # @before_create: null
  # @after_create: null


  # --- class methods
  @init: (attr, parent = null, is_new = false) ->
    new @(attr, parent, is_new)

  @to_s: ->
    if @_collection then @_collection._name else "embedded"

  @create: (attr, callback = undefined) ->
    attr.createdAt ||= new Date()
    attr = @before_create(attr) if @before_create
    doc = @init(attr, null, true)

    if callback?
      doc.save(attr, callback)
      null
    else
      doc = doc.save(attr)
      doc.initAttrsAndRelations(attr)
      if doc and @after_create
        @after_create(doc)
      else
        doc

  # find + modelize
  @where: (selector = {}, options = {}) ->
    self = @
    if @_debug
      console.info " --- WHERE ---"
      console.info "  #{_.singularize _.classify @to_s()}.where(#{JSON.stringify selector}#{if not _.isEmpty options then ','+JSON.stringify options else ''})"
    result = @find(selector, options).fetch()
    result = Relation.new self, result...
    result.setQuery selector
    console.info "  > found #{result.length}" if @_debug and result
    result

  @first: (selector = {}, options = {}) ->
    if @_debug
      console.info " --- FIRST ---"
      console.info "  #{_.singularize _.classify @to_s()}.first(#{JSON.stringify selector}#{if not _.isEmpty options then ','+JSON.stringify options else ''})"
    if doc = @_collection.findOne(selector, options)
      @init doc

  # kind of a silly method, just does a findOne with reverse sort on createdAt
  @last: (selector = {}, options = {}) ->
    options.sort = createdAt: -1
    if doc = @_collection.findOne(selector, options)
      @init doc

  @all: (options = {}) ->
    @where({}, options)

  # this doesn't perform a fetch, just generates a collection cursor
  @find: (selector = {}, options = {}) ->
    self = @
    # ***Important!*** Transform all docs in the collection to be an instance of our model
    unless options.transform
      options.transform = (doc) -> self.init(doc)

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
  # -- somewhat deprecated -- used to be used in @where function, which is replaced by the transform inside of @find
  @modelize: (cursor, parent = null) ->
    self = @
    models = cursor.map (i) -> self.init(i, parent)
    Relation.new self, models...


# for some reason underscore.inflection stopped working with Meteor 0.6.5.
# so for now we just use this simple singularize method instead of including the library
_.singularize = (s) ->
  s = s.replace /s$/, ""
