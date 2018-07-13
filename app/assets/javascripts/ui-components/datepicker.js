function initDatepicker(id,minDate,maxDate) {
  $("#"+id).datepicker({
    dateFormat:'mm/dd/yy',
    changeYear: true,
    changeMonth:true,
    yearRange: minDate.getFullYear()+':'+maxDate.getFullYear(),
    minDate:minDate,
    maxDate:maxDate
  })
  // Callbacks for datepicker
  .on("change", function (e) {
    validateDate(e, minDate, maxDate)
  });
}
