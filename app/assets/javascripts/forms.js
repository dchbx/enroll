// $(".date-picker").datepicker();

$(".date-picker").on("change", function () {
  console.log('picket loaded');
    var id = $(this).attr("id");
    var val = $("label[for='" + id + "']").text();
    $("#msg").text(val + " changed");
});

$(document).ready(function() {
  $("input.capital").keyup(function() {
    var val = $(this).val();
    val = val.replace(/_/g, '');
    $(this).val(val.toUpperCase());
  });

});
