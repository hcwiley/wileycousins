
function bindScroll(){
  $(window).unbind("scroll");
  $(window).on("scroll",function(e){
    var curPos = $(window).scrollTop();
    var top = 0;
    if($('#about').length > 0)
      top = $("#about").offset().top - $(".navbar").height();
    else if($('#pcb-design').length > 0)
      top = $("#pcb-design").offset().top - $(".navbar").height();
    else
      top = $(".navbar").height();
    //console.log(curPos+", "+top);
    if(curPos >= top ){
      if(!$(".navbar").hasClass("navbar-fixed-top") ){
        $(".home-link").removeClass("hidden");
        $(".navbar").addClass("navbar-fixed-top");
        $("#about").css("margin-top", $(".navbar").height()+"px");
      }
    }
    else {
      $(".navbar").removeClass("navbar-fixed-top");
      $("#about").css("margin-top", 0);
      $(".home-link").addClass("hidden");
    }
  });
}


function stripeResHandler(status, res) {
  var form;
  form = $("#enrollment-form");
  if (res.error) {
    form.find('.enrollment-errors').text(res.error.message);
    return form.find('button').prop('disabled', false);
  } else {
    form.append($("<input type='hidden' name='stripeToken' value='" + res.id + "'/>"));
    return form.get(0).submit();
  }
};

function bindEnrollmentForm() {
  $("#num-classes").change(function(){
    var val = $(this).val();
    if(val == "5")
      $("#total").text("7.52");
    else if(val == "15")
      $("#total").text("20.91");
    else if(val == "40")
      $("#total").text("51.80");
  });
  $("#enrollment-form #pay-online").click(function(e) {
    e.preventDefault();
    var form;
    form = $(this).closest('form');
    form.find('.first-buttons').remove();
    form.append($("#cc-info").removeClass('hidden'));
    $("#enrollment-form").submit(function(e) {
      e.preventDefault();
      form.find('button').prop('disabled', true);
      Stripe.card.createToken(form, stripeResHandler);
      return false;
    });
    return false;
  });
};

$(window).ready(function(){
  bindScroll();
  bindEnrollmentForm();
});
