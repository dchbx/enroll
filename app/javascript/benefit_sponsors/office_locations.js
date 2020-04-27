export function checkOLKind(element) {
  var addressKind = $(element).val();
  var row = $(element).closest(".row").next(".row").next(".row");
  if (addressKind == "primary") {
    row.find('#inputCounty').attr('required', true);
    row.find('#inputCounty').attr('disabled', true);
    row.find('#inputCounty').attr('data-target','zip-check.countySelect');
    row.find('#inputZip').attr('required', true);
    row.find('#inputZip').attr('data-action', 'change->zip-check#zipChange');
  } else {
    row.find('#inputCounty').removeAttr('required');
    row.find('#inputCounty').removeProp('required');
    row.find('#inputZip').removeAttr('data-action');
    row.find('#inputZip').removeProp('data-action');
    row.find('#inputZip').removeAttr('required');
    row.find('#inputZip').removeProp('required');
    row.find('#inputZip').removeAttr('data-options');
    row.find('#inputZip').removeProp('data-options');
    // removes blank option from select options
    //setTimeout(function() {
    //  element.options[0].remove()
    // },300)
  }
}
