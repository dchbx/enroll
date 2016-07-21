var Hints = ( function( window, undefined ) {

  function myPortalsLinkReminder() {
    $('.my-portal-links .dropdown-toggle').css({'color': '#007bc4;'});
    $('.dropdown[data-toggle="popover"]').popover('show');
    $('.popover-title').append('<button id="popovercloseid" type="button" class="close" style="position: absolute; top: 10px; right: 15px;" title="Don\'t Show Again" data-toggle="tooltip">&times;</button>');
    Freebies.tooltip();
    $('html').on('click', function(e) {
      if (typeof $(e.target).data('original-title') == 'undefined') {
        $('[data-original-title]').popover('hide');
      }
    });
    $('#popovercloseid').on('click', function() {
        $.ajax({
          context: this,
          type: "post",
          url: "/show_hints",
          dataType: 'script',
          beforeSend: function() {
          }
        }).done(function (data) {
          $('[data-original-title]').popover('hide');
        });
    });
  }

  return {
      myPortalsLinkReminder : myPortalsLinkReminder,
    };

} )( window );
