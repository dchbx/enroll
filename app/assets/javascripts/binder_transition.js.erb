var binderTransition = ( function( window, undefined ) {

function binder_transition_checkboxes () {
  var table = $('#binder-transition-dataTable').DataTable();
  var rowCount = $("#binder-transition-dataTable > tbody > tr").length;
  //checking with one because, we display a row with text "no data available" if there are no rows
  if(rowCount == 1){
    $('#binderSubmit').prop('disabled', true);
  }

  var checkBoxes = $('tbody .binderCheckBox');
  var headCheckBox = $('thead #checkall');

  $('tbody .binderCheckBox, thead #checkall').change(function () {
    var selectedCheckBoxes = checkBoxes.filter(':checked');
    var disabledCheckBoxes = checkBoxes.filter(':disabled');
    var enabledCheckBoxes = checkBoxes.filter(':enabled');
    var selectedDisabledCheckBoxes = checkBoxes.filter(":checked").filter(":disabled");
    var selectedDisabledCheckBoxesLength = selectedDisabledCheckBoxes.length;
    var selectedCheckBoxesLength = selectedCheckBoxes.length;
    var disabledCheckBoxesLength = disabledCheckBoxes.length;
    var enabledCheckBoxesLength = enabledCheckBoxes.length;
    var totalCheckBoxesLength = checkBoxes.length;
    checkBoxes.filter(':checked').filter(":disabled").prop("checked", false);
    if(selectedCheckBoxesLength < 1 || (selectedDisabledCheckBoxesLength == totalCheckBoxesLength)){
      $('#binderSubmit').prop('disabled', true);
    }else if(selectedCheckBoxesLength >= 1 ){
      $('#binderSubmit').prop('disabled', false);
    }

    if (selectedCheckBoxesLength != 0 && totalCheckBoxesLength != selectedCheckBoxesLength){
      headCheckBox.prop("indeterminate", true);
    }else if (totalCheckBoxesLength == selectedCheckBoxesLength){
      headCheckBox.prop({'indeterminate': false, 'checked': true });
    }else if(selectedCheckBoxesLength == 0){
      headCheckBox.prop({'indeterminate': false, 'checked': false });
    }else{
        headCheckBox.prop({'indeterminate': true, 'checked': false });
    }
  });

  $('#checkall').click(function () {
    $(':checkbox', table.rows().nodes()).prop('checked', this.checked);
  });

  checkBoxes.change();
}

return {
  binder_transition_checkboxes : binder_transition_checkboxes,
};
} )( window );