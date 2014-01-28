#= require jquery
#= require bootstrap.min
bindScroll = ->
  $(window).unbind "scroll"
  $(window).on "scroll", (e) ->
    curPos = $(window).scrollTop()
    top = 0
    #if $("#about").length > 0
    top = $($(".navbar.nav").siblings('div:not(.modal)')[1]).offset().top - $(".navbar").height()
    #else if $("#pcb-design").length > 0
      #top = $("#pcb-design").offset().top - $(".navbar").height()
    #else
      #top = $(".navbar").height()
    
    if curPos >= top
      unless $(".navbar").hasClass("navbar-fixed-top")
        $(".home-link").removeClass "hidden"
        $(".navbar").addClass "navbar-fixed-top"
        $("#about").css "margin-top", $(".navbar").height() + "px"
    else
      $(".navbar").removeClass "navbar-fixed-top"
      $("#about").css "margin-top", 0
      $(".home-link").addClass "hidden"

stripeResHandler = (status, res) ->
  form = $("#enrollment-form")
  if res.error
    form.find(".enrollment-errors").text res.error.message
    form.find("button").prop "disabled", false
  else
    form.append("<input type='hidden' name='stripeToken' value='#{res.id}'/>")
    #form.get(0).submit()
    $.post form.attr('action'), form.serialize(), (res) ->
      form.html(res)
bindEnrollmentForm = ->
  $("#num-classes").change ->
    val = $(@).val()
    if val is "1"
      $("#total").text "7.52"
    else if val is "4"
      $("#total").text "20.91"
    else if val is "12"
      $("#total").text "51.80"

  $("#enrollment-form").submit (e) ->
    e.preventDefault()
    form = $("#enrollment-form")
    form.find("button").prop "disabled", true
    $.post form.attr('action'), form.serialize(), (res) ->
      form.html(res)
    false
  $("#enrollment-form #pay-online").click (e) ->
    e.preventDefault()
    $("#enrollment-form").unbind 'submit'
    form = $(@).closest("form")
    form.find(".first-buttons").remove()
    form.append $("#cc-info").removeClass("hidden")
    $("#enrollment-form").submit (e) ->
      e.preventDefault()
      form.find("button").prop "disabled", true
      Stripe.card.createToken form, stripeResHandler
      false

    false

$(window).ready ->
  bindScroll()
  bindEnrollmentForm()
  $("[data-toggle='tooltip']").tooltip()

