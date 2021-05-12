$(document).on('change', '#applicant_same_with_primary', function(){
  var target = $(this).parents('#applicant-address').find('#applicant-home-address-area');
  if ($(this).is(':checked')) {
    $(target).hide();
    $(this).parents('#applicant-address').find('#home-info').hide();
    $(target).find("#address_info .address_required").removeAttr('required');
  } else {
    $(target).show();
    $(this).parents('#applicant-address').find('#home-info').show();
    if (!$(target).find("#applicant_no_dc_address").is(':checked')){
      $(target).find("#address_info .address_required").attr('required', true);
    };
  }
});
