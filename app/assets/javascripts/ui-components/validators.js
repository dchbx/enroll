window.onload = function() {
  // Nothing for right now
}

function lettersOnly(input) {
  var regex = /[^a-z]/gi;
  input.value = input.value.replace(regex,"");
}


function toCurrency(element) {
  element.value = element.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1')
}

// Prevents dates entered outside of minDate/maxDate from being submitted
function validateDate(element, minDate, maxDate) {
  var selectedDate = new Date(element.target.value)
  
  if (selectedDate < minDate) {
    swal("Invalid Date!","Date entered is less then the minimum allowable date","error");
    element.target.value = '';
  }
  
  if (selectedDate > maxDate) {
    swal("Invalid Date!","Date entered exceeds maximum allowed date","error");
    element.target.value = '';
  }
}

// Prevents non numeric characters
function isNumberKey(evt){
  {
    var charCode = (evt.which) ? evt.which : event.keyCode
    if (charCode > 31 && (charCode < 48 || charCode > 57))
      return false;

    return true;
  }
}

// Formats dates for Benefit Applications
function getFormattedDate(date){
  var new_date = new Date(date)
  var dd = new_date.getUTCDate();
  var mm = new_date.getUTCMonth()+1;
  var yyyy = new_date.getUTCFullYear();
  if(dd<10) {
    dd='0'+dd
  }
  if(mm<10) {
    mm='0'+mm
  }
  formatted_date = mm+'/'+dd+'/'+yyyy;
  return formatted_date;
}