var FormHelpers = (function(window, undefined) {

  function cacheDom() {
    dom = $('html').html();
    return dom;
  }

  function preventUnload() {
    $(window).load(function() {
      $values_on_load = [];
      $('form input').each(function(index, value) {
        $values_on_load.push($(this).val());
      });
      $(document).one('click', "a", compareFormValues);
    });
  }

  function compareFormValues() {
    $values_on_exit = [];
    $('form input').each(function(index, value) {
      $values_on_exit.push($(this).val());
    });
    if ($values_on_exit.toString() == $values_on_load.toString()) {
    } else {
      var message = "You have unsaved changes. Are you sure you want to leave this page?"
      return confirm(message);
    }
  }

  function applyAsterisks() {
    var required_fields = $('input[required]');
    required_fields.each(function() {
      placeholder_text = $(this).attr('placeholder');
      $(this).attr('placeholder', placeholder_text+" *");
    });
  }

  return {
    cacheDom: cacheDom,
    preventUnload: preventUnload,
    applyAsterisks : applyAsterisks
  };

})(window);
