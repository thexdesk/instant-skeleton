
# destructure only what's needed
{strong,div,hr,form,button,h1,label,input} = DOM

require! {
  \./Input
  \./Footer
}

# HomePage
module.exports = component \HomePage page-mixins, ({{path,locals,session,everyone}:props}) ->
  name = session.get \name

  on-click = ~>
    sync-session! # sync across sessions
    @navigate R(\MyTodoPage)

  div class-name: \HomePage,
    # allow name to be set
    h1 void if name then "Greetings #name!" else 'Hello! What\'s Your Name?'
    hr void
    form {on-submit:-> false} [
      Input (session.cursor \name), {ref:\focus, placeholder:'Your Name'}
      button {title:'Open multiple browsers to test', on-click} \Save
    ]
    Footer {name, path, last-page:(session.get \lastPage)}
