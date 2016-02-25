
# Input
module.exports = ignore <[ focus ]>, component \Input ({cursor, auto-focus, ref}:opts) ->
  should-auto-focus = ref is \focus or auto-focus
  on-change  = (e) ->
    v = e.current-target.value
    if v?0 isnt ' ' # disallow space as first char
      cursor.update -> v

  options = {
    auto-focus
    on-change
    +controlled
    type: \text
    on-focus: -> if should-auto-focus then it.current-target.select! # select, too!
  } <<< opts

  # how to bind this input
  v = cursor.deref!
  if options.controlled
    options.value = v
  else # only default
    options.default-value = v

  DOM.input options
