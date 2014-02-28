class @HasManyRelation extends @Relation
  constructor: (klass, foreign_key, id, args...) ->
    @klass = klass
    @link = {}
    @link[foreign_key] = id
    @klass = klass
    @foreign_key = foreign_key
    @id = id
    @push.apply(@, args)

  @new: (klass, foreign_key, id, args...) ->
    new @(klass, foreign_key, id, args...)

  @fromRelation: (relation, foreign_key, id) ->
    new @(relation.relationClass(), foreign_key, id, relation.toArray()...)

  create: (attr) ->
    super _.extend(attr, @link)
