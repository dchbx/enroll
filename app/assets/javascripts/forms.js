// $(".date-picker").datepicker();

$(".date-picker").on("change", function () {
    var id = $(this).attr("id");
    var val = $("label[for='" + id + "']").text();
    $("#msg").text(val + " changed");
});

$(document).ready(function() {
    $("input.capital").keyup(function() {
        var val = $(this).val();
        val = val.replace(/_/g, '');
        $(this).val(val.toUpperCase());
    });

});

var captchaWidget;
var captchaSiteKey;

window.setCaptchaSiteKey = function(key) {
    captchaSiteKey = key
}

$(document).ready(function(){
  if (typeof grecaptcha !== 'undefined') {
    $('#invisible-recaptcha-form').on('submit', function(event) {
        if(grecaptcha.getResponse(captchaWidget) ==''){
            $('.recaptcha-error').text('reCAPTCHA verification failed, please try again.').show(300)
            event.preventDefault();
        }else{
            $('.recaptcha-error').text('').hide(100)
        }
    });
  }
})

var captchaSubmit = function () {
    if($('.recaptcha-error').length > 0){
        $('.recaptcha-error').hide(100)
    }
};

var loadCaptchaWidget = function(key) {
    captchaWidget = grecaptcha.render('captcha-widget',
        {sitekey: captchaSiteKey, theme: "light", callback: "captchaSubmit"});
}
