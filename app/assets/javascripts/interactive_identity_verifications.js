$(document).ready(function() {
  
  $('.v-type-status').each(function(i) {
    let value = $(this).text().replace(/\s/g, "") ;

    if (value != "Verified") {
      $('#btn-continue').addClass('blocking');
    }
  });
  
  $('.fa-trash-o').click(function() {
    location.reload(true);
  })
});
