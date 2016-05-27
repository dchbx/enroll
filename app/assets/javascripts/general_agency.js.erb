$(document).on('page:update', function() {
  Freebies.tooltip();

  $('#general_agency_id').on('change', function() {
    check_allow_assign(this);
  });

  $("input[name='employer_ids[]']").on('change', function() {
    check_allow_assign(this);
  });
});

function check_allow_assign(element) {

  var allow_assign = ($('#general_agency_id').val() != undefined && $('#general_agency_id').val() != "") && $("[name='employer_ids[]']").is(':checked');
  var allow_unassign = false;
  $('input.employer_id_checkbox').each(function (){
    if($(this).is(':checked') && $(this).parent().parent().find("td.general_agency a").length > 0){
      allow_unassign =true;
      return false;
    }
  });

  if (allow_assign){
    $('#assign_general_agency').removeAttr("disabled");
  }else{
    $('#assign_general_agency').attr("disabled","disabled");
  }
  if (allow_unassign){
    $('#unassign_general_agency').removeAttr("disabled");
  }else{
    $('#unassign_general_agency').attr("disabled","disabled");
  }
}

$(document).on('click', 'input#select_all_tag', function(){
  if($(this).is(':checked')){
    $('input.employer_id_checkbox').prop('checked', true);
  }else{
    $('input.employer_id_checkbox').removeProp('checked');
  }
  check_allow_assign(this);
});

function enableGeneralAgenciesFilters() {
  var url = '/exchanges/hbx_profiles/general_agency_index.js';

  $('div[name=general_agencies_tab] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      $.ajax({
        url: url,
        type: "GET",
        data : { 'status': filter }
      });
    });
  });
}
