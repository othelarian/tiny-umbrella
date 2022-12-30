import {DiceRoller} from '@dice-roller/rpg-dice-roller'

getId = (id) -> document.getElementById id

Umbrella =
  clear: -> getId('histo').replaceChildren()
  init: ->
    if navigator.serviceWorker?
      navigator.serviceWorker.register 'sw.js', {scope: '/tiny-umbrella/'}
    window.addEventListener 'resize', Umbrella.resize
    Umbrella.roller = new DiceRoller()
  flip: ->
    if Umbrella.flipped
      col.removeAttribute 'style' for col in document.querySelectorAll('.cols')
      Umbrella.flipped = false
    else
      getId('col1').setAttribute 'style', 'display:none'
      getId('col2').setAttribute 'style', 'display:block'
      Umbrella.flipped = true
  flipped: false
  resize: ->
    if Umbrella.flipped and window.innerWidth > 700 then Umbrella.flip()
  roll: (inp) ->
    frm = if inp is 'input' then getId('theimp').value else inp
    getId('res').innerText =
      try
        r = Umbrella.roller.roll frm
        elt = document.createElement 'div'
        elt.innerText = r.output
        getId('histo').prepend elt
        r.total
      catch _
        'Error!'
  roller: null

window.Umbrella = Umbrella

