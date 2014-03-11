
$(window).ready ->
  $(".mark-used").click (e)->
    me = $(@)
    classes = $(@).parents('.classes')
    _class = classes.data('classes').pop()
    $.post "/classes/#{_class._id}", "action=used", (res) ->
      classes.find('.num').text parseInt(classes.find('.num').text())-1


  $(".delete-class").click (e)->
    me = $(@)
    classes = $(@).parents('.classes')
    _class = classes.data('classes').pop()
    $.post "/classes/#{_class._id}", "action=delete", (res) ->
      classes.find('.num').text parseInt(classes.find('.num').text())-1
