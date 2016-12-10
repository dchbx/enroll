var ConsumerRole = (function( window, undefined ) {
  function initialize() {
    $("#person_no_dc_address, #dependent_no_dc_address, #no_dc_address").click(function(event){
      toggle_no_dc_address_reasons(this);
      check_state_for_no_dc_address($(this).parents('#address_info').find('#state_id'));
      event.stopPropagation();
    });

    $('#radio_homeless, #radio_outside').click(function(){
      show_mailing_address_fields($(this).parents('#address_info').next('.form-action'));
      check_mailing_address_fields();
    });

    $('#address_info + span.form-action').click(function(){
      toggle_mailing_address_fields(this);
    });

    $('#state_id').change(function(event){
      check_state_for_no_dc_address(this);
      event.stopPropagation();
    });

    $('.mailing-div .address_1, .mailing-div .city, .mailing-div select, .mailing-div .zip').change(function(){
      check_mailing_address_fields();
    });
  }

  function toggle_no_dc_address_reasons(target) {
    var address_target = $(target).parents('#address_info');
    if (target.checked) {
      address_target.find('.home-div.no-dc-address-reasons').show();
      address_target.find('#radio_homeless').attr('required', true);
      address_target.find('#radio_outside').attr('required', true);
      address_target.find('.address_required').removeAttr('required');
    } else {
      address_target.find('#radio_homeless').attr('required', false).removeAttr('checked');
      address_target.find('#radio_outside').attr('required', false).removeAttr('checked');
      address_target.find('.home-div.no-dc-address-reasons').hide();
      address_target.find('.address_required').attr('required', true);
      $('#mailing_address_required_msg').addClass('hidden');
    };
  }

  function toggle_mailing_address_fields(target) {
    if ($(target).text() == "Add Mailing Address"){
      $(target).text('Remove Mailing Address');
      $('.row-form-wrapper.mailing-div').show();
    } else if ($(target).text() == "Remove Mailing Address"){
      $(target).text('Add Mailing Address');
      $('.mailing-div').hide();
      $(".mailing-div input[type='text']").val("");
      $('.mailing-div .label-floatlabel').hide();
    }
  }

  function show_mailing_address_fields(target) {
    if ($(target).text() == "Add Mailing Address"){
      $(target).text('Remove Mailing Address');
      $(target).prev('#address_info').find('.row-form-wrapper.mailing-div').show();
    }
  }

  function show_mailing_address_required_msg() {
    $('#mailing_address_required_msg').removeClass('hidden');
  }

  function check_state_for_no_dc_address(target) {
    if (!$("#no_dc_address").is(':checked') && $(target).val() != 'DC') {
      alert('You have selected a Non DC state, please check No DC Address');
    }
  }

  function check_mailing_address_fields(target) {
    var mailing_address = $(".mailing-div .address_1").val();
    var mailing_city = $(".mailing-div .city").val();
    var mailing_state = $(".mailing-div select").val();
    var mailing_zip = $(".mailing-div .zip").val();
    if (mailing_address!="" && mailing_city!="" && mailing_state!="" && mailing_zip!="") {
      $("#mailing_address_required_msg").addClass('hidden');
    } else {
      show_mailing_address_required_msg();
    }
  }

  return {
    initialize: initialize,
    check_state_for_no_dc_address: check_state_for_no_dc_address,
  };
})( window );
