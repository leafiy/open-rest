_           = require 'underscore'
Sequelize   = require 'sequelize'
dc          = decodeURIComponent
pageParams  = require './page-params'

defaultPagination =
  maxResults: 10
  maxStartIndex: 10000
  maxResultsLimit: 5000

module.exports =

  dimensions: (Model, params, _dims) ->
    dimensions = params.dimensions
    # 如果 dimensions 定义了
    return unless dimensions
    # 但是不为字符串，直接返回错误
    throw Error('Dimensions must be a string') unless _.isString dimensions
    # 循环遍历维度设置
    dims = []
    for dim in dimensions.split(',')
      # 如果不在允许的范围内，则直接报错
      key = Model.stats.dimensions[dim]
      # 处理动态维度配置
      key = _dims[dim] if (not key) and _dims and _dims[dim]
      throw Error('Dimensions dont allowed') unless key
      attr = {}
      attr[key] = dim
      dims.push "#{key} AS `#{dim}`"
    return dims

  group: (mets) ->
    return unless mets
    return unless _.isArray mets
    return unless mets.length
    _.map(mets, (x) -> x.split(' AS ')[1])

  metrics: (Model, params, _mets) ->
    metrics = params.metrics
    # 如果没有设置了指标
    throw Error('Metrics must be required') unless metrics
    # 如果设置了，但是不为字符串，直接返回错误
    throw Error('Metrics must be a string') unless _.isString metrics
    # 循环遍历所有的指标
    mets = []
    for met in metrics.split(',')
      # 如果指标不在允许的范围内，则直接报错
      key = Model.stats.metrics[met]
      # 处理动态指标配置
      key = _mets[met] if (not key) and _mets and _mets[met]
      throw Error('Metrics dont allowed') unless key
      mets.push "#{key} AS `#{met}`"
    return mets

  filters: (Model, filters, _dims) ->
    $and = []
    # 如果没有设置了过滤条件
    return $and unless filters
    # 如果设置但是不为字符串，直接返回错误
    throw Error('Filters must be a string') unless _.isString filters
    for _and in filters.split(';')
      $or = []
      for _or in _and.split(',')
        [k, v] = _or.split('==')
        col = Model.rawAttributes[k]
        key = col and "`#{k}`" or Model.stats.dimensions[k]
        # 处理动态维度配置
        key = __dims[dim] if (not key) and _dims and _dims[dim]
        throw Error("Filters set error: #{k}") unless key
        $or.push ["#{key}=?", [dc v]]
      $and.push {$or}
    $and

  sort: (Model, params) ->
    {dimensions, metrics, sort}  = params
    return unless sort
    direction = 'ASC'

    if sort[0] is '-'
      direction = 'DESC'
      order = sort.substring(1)
    else
      order = sort

    allowSort = []
    for k in ['dimensions', 'metrics']
      if params[k] and _.isString params[k]
        allowSort = allowSort.concat params[k].split(',')
    return unless order in allowSort
    return "#{order} #{direction}"

  pageParams: (Model, params) ->
    pagination = Model.stats.pagination or defaultPagination
    pageParams(pagination, params)
