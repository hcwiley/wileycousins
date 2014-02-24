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
    $("input[name='cc-number']").attr 'type', 'password'
    $("input[name='cc-cvc']").attr 'type', 'password'
    $("input[name='cc-exp-month']").attr 'type', 'password'
    $("input[name='cc-exp-year']").attr 'type', 'password'
    $("input[name='cc-number']").val $("input[name='cc-number']").val().replace /\d/g, '#'
    $("input[name='cc-cvc']").val $("input[name='cc-cvc']").val().replace /\d/g, '#'
    $("input[name='cc-exp-month']").val $("input[name='cc-exp-month']").val().replace /\d/g, '#'
    $("input[name='cc-exp-year']").val $("input[name='cc-exp-year']").val().replace /\d/g, '#'
    form.get(0).submit()
    #$.post form.attr('action'), form.serialize(), (res) ->
      #form.html(res)

bindEnrollmentForm = ->
  $("a[href='#enroll']").click ->
    $("#class").val $(@).data 'class'
    $("#class").trigger 'change'
    $("#num-classes").trigger 'change'

  $("#circuits-kit").change ->
    $("#num-classes").trigger 'change'
    if $(@).val() == components_price
      $("#kit-check").modal 'show'

  $("#class").change ->
    val = $(@).val()
    if val is "intro-circuits"
      $("#enroll").removeClass('bg-blue').addClass 'bg-gray'
      $("#circuits-kit").parents(".form-group").removeClass 'hidden'
    else if val is "intro-programming"
      $("#enroll").removeClass('bg-gray').addClass 'bg-blue'
      $("#circuits-kit").parents(".form-group").addClass 'hidden'
    $("#class-title").text $("option[value='#{val}']").text()
    $("#num-classes").trigger 'change'

  $("#num-classes").change ->
    val = $(@).val()
    amt = 0
    if $("#class").val() == "intro-circuits"
      amt = parseInt $("#circuits-kit").val()
    if val is "1"
      amt = 10
    else if val is "4"
      amt = 40
    else if val is "12"
      amt = 100
    if $("#class").val() == 'intro-circuits'
      amt *= 2
      amt += parseInt $("#circuits-kit").val()
    # account for stripe transaction fee
    amt = (amt + 0.3)/(1-0.029)
    amt = Math.round(amt * 100) / 100
    if amt.toString().split('.')[1].length < 2
      amt = "#{amt}0"
    $("#total").text amt
    $("input[name='amount']").val amt

  $("#enrollment-form").submit (e) ->
    e.preventDefault()
    $("#num-classes").trigger 'change'
    form = $(@)
    form.find("button").prop "disabled", true
    Stripe.card.createToken form, stripeResHandler
    false
  $("#num-classes").trigger 'change'

$(window).ready ->
  bindScroll()
  bindEnrollmentForm()
  $("[data-toggle='tooltip']").tooltip()
  $("[data-toggle='popover']").popover()

