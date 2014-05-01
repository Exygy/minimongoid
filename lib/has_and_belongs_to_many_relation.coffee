class @HasAndBelongsToManyRelation extends @Relation
  constructor: (instance, klass, identifier, inverse_identifier, id, args...) ->
    @instance = instance
    @inverse_identifier = inverse_identifier
    @link = {}
    @link[identifier] = [id]
    super klass, args...

  @new: (instance, klass, identifier, inverse_identifier, id, args...) ->
    new @(instance, klass, identifier, inverse_identifier, id, args...)

  @fromRelation: (relation, instance, identifier, inverse_identifier, id) ->
    new @(instance, relation.relationClass(), identifier, inverse_identifier, id, relation.toArray()...)

  create: (attr) ->
    obj = super _.extend(attr, @link)
    attr = {}
    if @instance[@inverse_identifier].length == 0
      attr[@inverse_identifier] = [obj.id]
      @instance.update attr
    else
      @instance.push(attr)
    obj
    
