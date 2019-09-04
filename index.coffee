_arity = (n, fn) ->
  switch n
    when 0 then -> fn.apply @, arguments
    when 1 then (a) -> fn.apply @, arguments
    when 2 then (a, b) -> fn.apply @, arguments
    when 3 then (a, b, c) -> fn.apply @, arguments
    when 4 then (a, b, c, d) -> fn.apply @, arguments
    when 5 then (a, b, c, d, e) -> fn.apply @, arguments
    when 6 then (a, b, c, d, e, f) -> fn.apply @, arguments
    when 7 then (a, b, c, d, e, f, g) -> fn.apply @, arguments
    when 8 then (a, b, c, d, e, f, g, h) -> fn.apply @, arguments
    when 9 then (a, b, c, d, e, f, g, h, i) -> fn.apply @, arguments
    when 10 then (a, b, c, d, e, f, g, h, i, j) -> fn.apply @, arguments
    when 11 then (a, b, c, d, e, f, g, h, i, j, k) -> fn.apply @, arguments
    when 12 then (a, b, c, d, e, f, g, h, i, j, k, l) -> fn.apply @, arguments
    else

_copy = (list) -> Array::slice.call list
_curry = (fn, currentArgs, remainingArity) ->
  return fn.apply @, currentArgs if remainingArity <= 0
  _arity remainingArity, ->
    calledArgs = _copy arguments
    _curry fn, currentArgs.concat(calledArgs), remainingArity - calledArgs.length
_pipe = (f, g) -> -> g.call @, f.apply @, arguments

ƒ = (fn) -> _curry fn, [], fn.length
ƒ.arity = ƒ _arity

# Lists
ƒ.map = ƒ (fn, list) -> list.map fn
ƒ.filter = ƒ (fn, list) -> list.filter fn
ƒ.reduce = ƒ (fn, acc, list) ->
  acc = fn acc, item for item in list
  acc
ƒ.slice = ƒ (from, to, list) -> list.slice from, to
ƒ.nth = ƒ (n, list) ->
  n = list.length + n if n < 0
  list[n]
ƒ.tail = ƒ.slice 1, Infinity
ƒ.init = ƒ.slice 0, -1
ƒ.first = ƒ.nth 0
ƒ.last = ƒ.nth -1
ƒ.reverse = (list) -> _copy(list).reverse()
ƒ.lengthfn = (list) -> list.length
ƒ.append = ƒ (item, list) -> list.concat [item]
ƒ.prepend = ƒ (item, list) -> [item].concat list
ƒ.drop = ƒ (n, list) -> ƒ.slice Math.max(0, n), Infinity, list
ƒ.take = ƒ (n, list) -> ƒ.slice 0, Math.max(0, n), list
ƒ.splitAt = ƒ (n, list) -> [
  ƒ.slice 0, n, list
  ƒ.slice n, list.length, list
]
ƒ.any = ƒ (fn, list) ->
  return yes for item in list when fn item
  no
ƒ.all = ƒ (fn, list) ->
  return no for item in list when not fn item
  yes
ƒ.zip = ƒ (list1, list2) ->
  [list1[i], list2[i]] for i in [0...Math.min list1.length, list2.length]
ƒ.of = (a) -> [a]
ƒ.pluck = (prop) -> ƒ.map ƒ.prop prop
ƒ.aperture = ƒ (n, list) ->
  ƒ.slice list, i, i + n for i in [0...list.length - (n - 1)]
ƒ.sort = ƒ (fn, list) -> list.slice(0).sort fn
ƒ.asc = ƒ (fn, list) ->
  sort = ƒ.sort (a, b) ->
    fa = fn a
    fb = fn b
    return 1 if fa > fb
    return -1 if fa < fb
    0
  sort list
ƒ.desc = ƒ (fn, list) ->
  sort = ƒ.sort (a, b) ->
    fa = fn a
    fb = fn b
    return 1 if fa < fb
    return -1 if fa > fb
    0
  sort list
ƒ.find = ƒ (fn, list) ->
  for item in list
    return item if fn item
  undefined

# Flow
ƒ.pipe = (first, args...) ->
  ƒ _arity first.length,
    ƒ.reduce ((f, g) -> -> g.call @, f.apply @, arguments),
      first,
      args
ƒ.compose = -> ƒ.pipe.apply @, ƒ.reverse arguments
ƒ.both = ƒ (fn1, fn2) ->
  _arity Math.min(fn1.length, fn2.length), ->
    fn1.apply(@, arguments) and fn2.apply(@, arguments)
ƒ.either = ƒ (fn1, fn2) ->
  _arity Math.min(fn1.length, fn2.length), ->
    fn1.apply(@, arguments) or fn2.apply(@, arguments)
ƒ.converge = ƒ (fn, fns) ->
  arity = reduce Math.max, 0, ƒ.pluck 'length', fns
  ƒ _arity arity, (args...) ->
    context = @
    fn.apply context, ƒ.map ((fn) -> fn.apply(context, args)), fns
ƒ.identity = (n) -> n
ƒ.always = ƒ (n, _) -> n
ƒ.ap = ƒ (fns, list) ->
  ƒ.reduce ((acc, f) -> ƒ.concat acc, map f, list), [], fns
ƒ.applyFn = ƒ (fn, args) -> fn.apply @, args
ƒ.callFn = (fn, args...) -> fn.apply @, args

# Object
ƒ.prop = ƒ (prop, obj) -> obj[prop]
ƒ.propEq = ƒ (prop, value, obj) -> obj[prop] is value
ƒ.isEmpty = (obj) -> obj is ''
ƒ.isNil = (obj) -> !obj?
ƒ.exists = ƒ.compose ƒ.not, ƒ.either(ƒ.isEmpty, ƒ.isNil), ƒ.prop
ƒ.isValid = ƒ (validate, prop) -> ƒ.compose validate, ƒ.prop prop

# Math
ƒ.add = ƒ (a, b) -> a + b
ƒ.sub = ƒ (a, b) -> a - b
ƒ.mult = ƒ (a, b) -> a * b
ƒ.div = ƒ (a, b) -> a / b
ƒ.dec = (n) -> n - 1
ƒ.inc = (n) -> n + 1
ƒ.mod = ƒ (m, p) -> ((m % p) + p) % p
ƒ.and = ƒ (a, b) -> a and b
ƒ.or = ƒ (a, b) -> a or b
ƒ.not = (a) -> not a

# Stats
ƒ.sum = ƒ.reduce ƒ.add, 0
ƒ.avg = (list) -> ƒ.sum(list) / list.length
ƒ.median = (list) ->
  return NaN if list.length is 0
  list = _copy list
  list.sort (a, b) -> if a < b then -1 else if a > b then 1 else 0
  list[Math.floor list.length / 2]

module.exports = ƒ
