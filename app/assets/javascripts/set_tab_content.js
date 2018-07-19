function set_tab_content(partial) {
  $('.flash').remove();
  $('#inbox > #tabContent').html(partial);
}

function set_active_ontab(tab_id) {
  $(tab_id).siblings().each(function(){
    $(this).removeClass('active');
  });
  $(tab_id).addClass('active');
}

function set_broker_agency_content(partial) {
  $('#broker_agency_panel > #tabContent').html(partial);
}


function setTabContent(partial) {
  $('.flash').remove();
  $('#myTabContent').html(partial);
}
