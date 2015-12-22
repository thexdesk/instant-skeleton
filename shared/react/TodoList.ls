
# destructure only what's needed
{a,ol,li,div,h2} = DOM

require! {
  \./ActiveDate
  \./Input
  \./Check
}


# TodoList
TodoList = component \TodoList ({todos, visible, search, name, on-delete, on-change, show-name}) ->
  # figure visible todos from ui selection
  cn = -> cx {active:(visible.deref! or \all) is it}
  show-only = (active) ->
    visible.update -> active
    window.scroll-to 0 0
    sync-session!

  list = todos
    .filter (todo) -> # show visible todos only
      return false unless todo.get # guard
      c = todo.get \completed
      switch visible.deref! or \all
        | \all       => true
        | \active    => !c
        | \completed => c
    .filter (todo) -> # show search-filtered todos only
      v = search.deref!
      return false unless todo.get # guard
      return true unless v         # guard
      ((todo.get \title).index-of v) >= 0

  save-edit = (e, key) ->
    todos.update-in [key, \title], ->
      on-change!
      e.current-target.value

  # todo list
  ol void [
    Input {type:\search, key:\search cursor: search, tab-index: 1, placeholder: 'Search', +spell-check}
    h2 key: \name, name
    if list.count!
      sorted = list.sort (a, b) -> (b.get \date) - (a.get \date) # reverse chron
        .entries!
      # FIXME hack until "for x of* y!" es6 iterators
      # https://github.com/gkz/LiveScript/issues/667
      while sorted.next!value
        let key = that.0
          show-date = if todos.has-in [key, \completed-at] then [key, \completed-at] else [key, \date]
          li {key} [
            Check {
              cursor:    todos.cursor [key, \completed]
              on-change: -> # save completion
                on-change if it.deref!
                  todos.update-in [key, \completed-at], -> new Date!get-time!
                else
                  todos.delete-in [key, \completed-at]
            }
            Input { # saves edits
              key: \title
              cursor: (todos.cursor [key, \title])
              on-blur:   -> save-edit it, key
              on-key-up: -> if it.key-code is 13 then save-edit it, key
              +spell-check
            }
            div {key:\fx class-name:\fx}
            ActiveDate {key: \date, cursor: (todos.cursor show-date), title:(todos.get-in [key, \name])} # author's name
            div {
              key: \delete
              title: \Delete
              class-name: \delete,
              on-click: ->
                if confirm 'Permanently delete?'
                  todos.delete key
                  if on-delete then on-delete!
            }, \x
          ]
    else
      li key:\placeholder, [ div {class-name:\placeholder} '(empty)' ]

    # filters
    div {key:\actions class-name:\actions} [
      a {key: \all on-click:(-> show-only \all), class-name:'nofx ' + cn \all} \All
      a {key: \active on-click:(-> show-only \active), class-name:'nofx ' + cn \active} \Active
      a {key: \completed on-click:(-> show-only \completed), class-name:'nofx ' + cn \completed} \Completed
    ]
  ]

module.exports = ignore <[ name onDelete onChange showName ]> TodoList
