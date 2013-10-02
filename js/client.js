
function bindScroll(){
  $(window).unbind("scroll");
  $(window).on("scroll",function(e){
    var curPos = $(window).scrollTop();
    var top = $("#about").offset().top - $(".navbar").height();
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

$(window).ready(function(){
  bindScroll();
});
