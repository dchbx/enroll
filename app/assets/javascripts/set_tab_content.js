function set_tab_content(partial) {
  $('#inbox .col-md-10').html(partial);
}

function set_active_ontab(tab_id) {
  $(tab_id).siblings().each(function(){
    $(this).removeClass('active');
  });
  $(tab_id).addClass('active');
}

function set_broker_agency_content(partial) {
  $('#broker_agency_panel .col-md-10').html(partial);
}


function setTabContent(partial) {
  $('#myTabContent').html(partial);
}
