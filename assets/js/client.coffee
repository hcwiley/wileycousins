#= require jquery
bindScroll = ->
  $(window).unbind "scroll"
  $(window).on "scroll", (e) ->
    curPos = $(window).scrollTop()
    top = 0
    if $("#about").length > 0
      top = $("#about").offset().top - $(".navbar").height()
    else if $("#pcb-design").length > 0
      top = $("#pcb-design").offset().top - $(".navbar").height()
    else
      top = $(".navbar").height()
    
    #console.log(curPos+", "+top);
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
  form = undefined
  form = $("#enrollment-form")
  if res.error
    form.find(".enrollment-errors").text res.error.message
    form.find("button").prop "disabled", false
  else
    form.append $("<input type='hidden' name='stripeToken' value='" + res.id + "'/>")
    form.get(0).submit()
bindEnrollmentForm = ->
  $("#num-classes").change ->
    val = $(this).val()
    if val is "5"
      $("#total").text "7.52"
    else if val is "15"
      $("#total").text "20.91"
    else $("#total").text "51.80"  if val is "40"

  $("#enrollment-form #pay-online").click (e) ->
    e.preventDefault()
    form = undefined
    form = $(this).closest("form")
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

