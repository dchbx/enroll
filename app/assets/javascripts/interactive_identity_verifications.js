$('.outstanding-ridp-documents').ready(function() {
  $('.v-type-status').each(function() {
    var value = $(this).text().replace(/\s/g, "");
    if (value != "Verified") {
      $('#btn-continue').addClass('blocking');
    }
  });
  $('.fa-trash-o').click(function() {
    location.reload(true);
  })
});
