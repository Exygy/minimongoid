global = @

class @Minimongoid
  # --- instance vars
  id: undefined
  errors: false
  # attr: {}

  # --- instance methods 
  constructor: (attr = {}, parent = null) ->
    if attr._id
      if @constructor._object_id
        @id = attr._id._str
      else
        @id = attr._id
      @_id = @id
    # set up errors var

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
    for attr, val of @constructor.defaults
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
            return global[class_name].where mod_selector, options


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
          if global[class_name] and self[identifier] and self[identifier].length
            return global[class_name].where mod_selector, options
          else
            return []



  # /--------------------
  # DEPRECATED: r() and related() methods 
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

  save: (attr = {}) ->
    # reset errors before running isValid()
    @errors = false

    for k,v of attr
      @[k] = v
    return @ if not @isValid()

    # attr['_type'] = @constructor._type if @constructor._type?
    
    if @id?
      @constructor._collection.update @id, { $set: attr }
    else
      @id = @_id = @constructor._collection.insert attr
    
    if @constructor.after_save
      @constructor.after_save(@)

    return @

  update: (attr) ->
    @save(attr)

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

  destroy: ->
    if @id?
      @constructor._collection.remove @id
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

  @to_s: ->
    if @_collection then @_collection._name else "embedded"

  @create: (attr) ->
    attr.createdAt ||= new Date()
    attr = @before_create(attr) if @before_create
    doc = @init(attr)
    doc = doc.save(attr)
    if doc and @after_create
      @after_create(doc)
    else
      doc

  # find + modelize
  @where: (selector = {}, options = {}) ->
    if @_debug
      console.info " --- WHERE ---"
      console.info "  #{_.singularize _.classify @to_s()}.where(#{JSON.stringify selector}#{if not _.isEmpty options then ','+JSON.stringify options else ''})"
    result = @modelize @find(selector, options)
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



# for some reason underscore.inflection stopped working with Meteor 0.6.5. 
# so for now we just use this simple singularize method instead of including the library
_.singularize = (s) ->
  s = s.replace /s$/, "" 