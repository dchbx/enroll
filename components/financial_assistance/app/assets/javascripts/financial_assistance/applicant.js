function applyFaaListenersFor(target) {
  // target is person or dependent

  $("input[name='" + target + "[us_citizen]']").change(function() {
    $('#vlp_documents_container').hide();
    $('#vlp_documents_container .vlp_doc_area').html("");
    $("input[name='" + target + "[naturalized_citizen]']").attr('checked', false);
    $("input[name='" + target + "[eligible_immigration_status]']").attr('checked', false);
    if ($(this).val() == 'true') {
      $('#naturalized_citizen_container').show();
      $('#immigration_status_container').hide();
      $("#" + target + "_naturalized_citizen_true").attr('required');
      $("#" + target + "_naturalized_citizen_false").attr('required');
    } else {
      $('#naturalized_citizen_container').hide();
      $('#immigration_status_container').show();
      $("#" + target + "_naturalized_citizen_true").removeAttr('required');
      $("#" + target + "_naturalized_citizen_false").removeAttr('required');
    }
  });

  $("input[name='" + target + "[naturalized_citizen]']").change(function() {
    var selected_doc_type = $('#naturalization_doc_type').val();
    if ($(this).val() == 'true') {
      $('#vlp_documents_container').show();
      $('#naturalization_doc_type_select').show();
      $('#immigration_doc_type_select').hide();
      showOnly(selected_doc_type);
    } else {
      $('#vlp_documents_container').hide();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').hide();
      $('#vlp_documents_container .vlp_doc_area').html("");
    }
  });

  $("input[name='" + target + "[eligible_immigration_status]']").change(function() {
    var selected_doc_type = $('#immigration_doc_type').val();
    if ($(this).val() == 'true') {
      $('#vlp_documents_container').show();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').show();
      showOnly(selected_doc_type);
    } else {
      $('#vlp_documents_container').hide();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').hide();
      $('#vlp_documents_container .vlp_doc_area').html("");
    }
  });

  $("input[name='" + target + "[indian_tribe_member]']").change(function() {
    if ($(this).val() == 'true') {
      $('#tribal_container').show();
    } else {
      $('#tribal_container').hide();
      $('#tribal_id').val("");
    }
  });
}

$(document).on('change', '#applicant_same_with_primary', function(){
  var target = $(this).parents('#applicant-address').find('#applicant-home-address-area');
  if ($(this).is(':checked')) {
    $(target).hide();
    $(target).find("#address_info .address_required").removeAttr('required');
  } else {
    $(target).show();
    if (!$(target).find("#applicant_no_dc_address").is(':checked')){
      $(target).find("#address_info .address_required").attr('required', true);
    };
  }
});
