$(document).on('click', 'div.alert-warning a.close', function(){
  var content = $(this).parent('.alert-warning').text();
  if (content != undefined && content != ""){
    content = content.trim().replace(/^×/, '').trim();
    $.ajax({
      type: "GET",
      data:{content: content},
      url: "/exchanges/announcements/dismiss"
    });
  }
})
