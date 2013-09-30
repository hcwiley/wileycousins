
function bindScroll(){
  $(window).unbind("scroll");
  $(window).on("scroll",function(e){
    var curPos = $(window).scrollTop();
    var top = $(".navbar").offset().top;
    //console.log(curPos+", "+top);
    if(curPos >= top ){
      if(!$(".navbar").hasClass("navbar-fixed-top") ){
        $(".navbar").addClass("navbar-fixed-top");
        $("#about").css("top", $(".navbar").height()+"px");
      }
    }
    else {
      $(".navbar").removeClass("navbar-fixed-top");
      $("#about").css("top", 0);
    }
  });
}

$(window).ready(function(){
  bindScroll();
});
