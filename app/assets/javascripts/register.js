var Register = ( function( window, undefined ) {
  var strPassword;
  var charPassword;
  var minPasswordLength = 8;
  var baseScore = 0, score = 0;
  
  var num = {};
  num.Excess = 0;
  num.Upper = 0;
  num.Numbers = 0;
  num.Symbols = 0;

  var bonus = {};
  bonus.Excess = 3;
  bonus.Upper = 4;
  bonus.Numbers = 5;
  bonus.Symbols = 5;
  bonus.Combo = 0; 
  bonus.FlatLower = 0;
  bonus.FlatNumber = 0;

  function initialize() {
    outputResult();
    $('#signup #user_oim_id').keyup(function() {
    }).focus(function() {
      $('.username_tooltip').show();
      if($(window).width() <= 480) {
        $('.tooltip_box.username_tooltip').css('top','0px');
      }
      if($(window).width() <= 400) {
        $('.tooltip_box.user_tooltip').css('margin-top','45px');
        $('.tooltip_box.user_tooltip').css('top','-60px');
      }
    }).blur(function() {
      $('.username_tooltip').hide();
    });

    /* check password validation */
    $('#signup #user_password').keyup(function() {
      onkeycheckForm();
      checkVal();
    }).focus(function() {
      onkeycheckForm();
      $('#pswd_info').show();
      if($(window).width() <= 480) {
        $('.tooltip_box#pswd_info').css('top','-60px');
      }
    }).blur(function() {
      $('#pswd_info').hide();
    });

    /* check confirm password validation */
    $('#signup #user_password_confirmation').keyup(function() {
      var pas = $("#user_password");
      var con_pas = $('#user_password_confirmation');
      var pass1 = pas.val();
      var pass2 = con_pas.val();
      var status;

      $('.con-pass').removeClass('conpass-success').text('');
      $('.con-pass').removeClass('conpass-false').text('');
      if(pass1 != '' && pass2.length > 0) {
        $('#user_password_confirmation').parent('.form-group').removeClass('has-error');
        if((pass1 != "" && pass1 != pass2)) {
          $('.con-pass').addClass('conpass-false').text('Match');
          con_pas.focus();
          return false;
        } else {
          $('.con-pass').addClass('conpass-success').text('Match');
        }
      }
    });

    $('#signup form#new_user').submit(function(e){
      if (checkForm()){
        return true;
      } else {
        e.preventDefault && e.preventDefault();
        return false;
      }
    })
  }

  function onkeycheckForm(form) {
    var oim_id = $('#user_oim_id');
    var pas = $("#user_password");
    var con_pas = $('#user_password_confirmation');
    var user_val = oim_id.val();
    var pass1 = pas.val();
    var pass2 = con_pas.val();
    var status = true;

    $('#length').removeClass('valid').addClass('invalid');
    $('#longer').removeClass('valid').addClass('invalid');
    $('#lower').removeClass('valid').addClass('invalid');
    $('#upper').removeClass('valid').addClass('invalid');
    $('#number').removeClass('valid').addClass('invalid');
    $('#spec_char').removeClass('valid').addClass('invalid');
    $('#mtt').removeClass('valid').addClass('invalid');
    $('#wh_space').removeClass('valid').addClass('invalid');
    $('#nm_uid').removeClass('valid').addClass('invalid');

    if(pass1.length > 0) {
      $('.alert').text();
      $('#user_password').parent('.form-group').removeClass('has-error');

      //validate the length
      if(pass1.length < 8) {
        $('#length').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#length').removeClass('invalid').addClass('valid');
      }
      //validate the longer length
      if(pass1.length > 20) {
        $('#longer').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#longer').removeClass('invalid').addClass('valid');
      }
      //validate lowercase letter
      if ( pass1.match(/[a-z]/) ) {
        $('#lower').removeClass('invalid').addClass('valid');
      } else {
        $('#lower').removeClass('valid').addClass('invalid');
        status = false;
      }
      //validate uppercase letter
      if(!pass1.match(/[A-Z]/)) {
        $('#upper').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#upper').removeClass('invalid').addClass('valid');
      }
      //validate the number
      if(!(pass1.match(/[0-9]/))){
        $('#number').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#number').removeClass('invalid').addClass('valid');
      }
      //validate special character
      if(!(pass1.match(/.[!,@,#,$,%,^,&,*,?,_,~,-,(,)]/))) {
        $('#spec_char').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#spec_char').removeClass('invalid').addClass('valid');
      }
      //validate white space
      if (!(pass1.match(/\s/)) ) {
        $('#wh_space').removeClass('invalid').addClass('valid');
      } else {
        $('#wh_space').removeClass('valid').addClass('invalid');
        status = false;
      }
      //validate not match user id
      if (user_val.length > 0 && pass1.indexOf(user_val) >= 0) {
        $('#nm_uid').removeClass('valid').addClass('invalid');
        status = false;
      } else {
        $('#nm_uid').removeClass('invalid').addClass('valid');
      }

      //validate repeated no more than 4
      var max_repeats = 4;
      pass_str = pass1;
      var chars = pass_str.split('');
      var cmap = {};
      for (var i = 0; i < chars.length; i++) {
        if (! cmap.hasOwnProperty(chars[i])) cmap[chars[i]] = 0;
        cmap[chars[i]]++;
      }
      for (var p in cmap) {
        if (cmap[p] > max_repeats){
          $('#mtt').removeClass('valid').addClass('invalid');
          return false;
        } else {
          $('#mtt').removeClass('invalid').addClass('valid');
        }
      }
    }
    return status;
  }

  function checkVal(){
    init();

    if (charPassword.length >= minPasswordLength) {
      baseScore = 50; 
      analyzeString();  
      calcComplexity();   
    } else {
      baseScore = 0;
    }

    outputResult();
  }

  function init() {
    strPassword= $("#user_password").val();
    charPassword = strPassword.split("");

    num.Excess = 0;
    num.Upper = 0;
    num.Numbers = 0;
    num.Symbols = 0;
    bonus.Combo = 0; 
    bonus.FlatLower = 0;
    bonus.FlatNumber = 0;
    baseScore = 0;
    score =0;
  }

  function analyzeString() { 
    for (i=0; i<charPassword.length;i++) {
      if (charPassword[i].match(/[A-Z]/g)) {num.Upper++;}
      if (charPassword[i].match(/[0-9]/g)) {num.Numbers++;}
      if (charPassword[i].match(/(.*[!,@,#,$,%,^,&,*,?,_,~])/)) {num.Symbols++;} 
    }

    num.Excess = charPassword.length - minPasswordLength;

    if (num.Upper && num.Numbers && num.Symbols) {
      bonus.Combo = 25; 
    } else if ((num.Upper && num.Numbers) || (num.Upper && num.Symbols) || (num.Numbers && num.Symbols)) {
      bonus.Combo = 15; 
    }

    if (strPassword.match(/^[\sa-z]+$/)) { 
      bonus.FlatLower = -15;
    }

    if (strPassword.match(/^[\s0-9]+$/)) { 
      bonus.FlatNumber = -35;
    }
  }
  
  function calcComplexity() {
    score = baseScore + (num.Excess*bonus.Excess) + (num.Upper*bonus.Upper) + (num.Numbers*bonus.Numbers) + (num.Symbols*bonus.Symbols) + bonus.Combo + bonus.FlatLower + bonus.FlatNumber;
  } 
  
  function outputResult() {
    console.log(score);
    var complexity = $("#complexity");
    var pass_strength = $("#pass_strength");
    if ($("#user_password").val()== "") { 
      complexity.html("").removeClass("weak strong stronger strongest").addClass("default");
      pass_strength.html("");
    } else if (score<50) {
      complexity.html("").removeClass("strong stronger strongest").addClass("weak");
      pass_strength.html("Weak");
    } else if (score>=50 && score<75) {
      complexity.html("").removeClass("weak stronger strongest").addClass("strong");
      pass_strength.html("Average");
    } else if (score>=75 && score<100) {
      complexity.html("").removeClass("weak strong strongest").addClass("stronger");
      pass_strength.html("Strong");
    } else if (score>=100) {
      complexity.html("").addClass("strongest");
      pass_strength.html("Secure");
    }
  }

  function checkForm(form) {
    var oim_id = $('#user_oim_id');
    var pas = $("#user_password");
    var con_pas = $('#user_password_confirmation');
    var user_val = oim_id.val();
    var pass1 = pas.val();
    var pass2 = con_pas.val();
    var status = true;
    var pass1_status = true;

    $('.error-block').hide();
    $('.alert').text();
    $('.form-group').removeClass('has-error');
    $('#user_password').parent('.form-group').removeClass('has-error');
    $('#user_password_confirmation').parent('.form-group').removeClass('has-error');

    if(user_val == '') {
      oim_id.parent('.form-group').addClass('has-error');
      $('.error-block').show();
      $('.alert').removeClass('alert-success').addClass('alert-danger').text('You must complete the highlighted field(s).');
      status = false;
    }

    pass1_status = onkeycheckForm(form);
    if (pass1_status == false) {
      $('.error-block').show();
      $('.alert').removeClass('alert-success').addClass('alert-danger').text("Password didn't match with requirements.");
      pas.focus();
      $('#inputPassword').parent('.form-group').addClass('has-error');
      return false;
    }

    if(pass2 == ""){
      $('#conf_pass').parent('.form-group').addClass('has-error');
      $('.error-block').show();
      $('.alert').removeClass('alert-success').addClass('alert-danger').text("You must complete the highlighted field(s).");
      status = false;
    }

    if (status == false) {
      return false;
    }

    if((user_val != "" && pass1 != "" && pass2 != "" )) {
      if( pass1 == pass2 ) {
        $('#conf_pass').parent('.form-group').removeClass('has-error');
        return true;
      } else {
        $('#conf_pass').parent('.form-group').addClass('has-error');
        $('.error-block').show();
        $('.alert').removeClass('alert-success').addClass('alert-danger').text("Confirm password didn't match. Please try again.");
        return false;
      }
    }
  }

  function toggleEmail(element){
    $(element).val($.trim($(element).val()));
    var username= $(element).val();
    var email_regexp = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
    
    if(email_regexp.test(username)) {
      $('.email_field').addClass("hidden_field"); 
      $('.email_field input').val(""); 
    }else if(username.length == 0 ){
      $('.email_field').addClass("hidden_field"); 
      $('.email_field input').val("");
    }else{
      $('.email_field').removeClass("hidden_field");  
    }  
  }

  function trimEmail(element){
    $(element).val($.trim($(element).val()));
  }

  return {
    initialize : initialize,
    toggleEmail : toggleEmail,
    trimEmail: trimEmail
  };
} )( window );
