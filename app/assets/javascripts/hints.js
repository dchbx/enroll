var Hints = ( function( window, undefined ) {

  function myPortalsLinkReminder() {
    $('.my-portal-links .dropdown-toggle').css({'color': '#007bc4;'});
    $('.dropdown[data-toggle="popover"]').popover('show');
    $('.popover-title').append('<button id="popovercloseid" type="button" class="close" style="position: absolute; top: 10px; right: 15px;" title="Don\'t Show Again" data-toggle="tooltip">&times;</button>');
    Freebies.tooltip();
    $('body').on('click', function (e) {
      $('[data-toggle="popover"]').each(function () {
        //the 'is' for buttons that trigger popups
        //the 'has' for icons within a button that triggers a popup
        if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.popover').has(e.target).length === 0) {
          $(this).popover('hide');
        }
      });
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
