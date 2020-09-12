$(document).on('turbolinks:load', function () {
  $("#family-matrix").on("change", ".selected_relationship", function () {

    $.ajax({
      url: window.location.pathname.replace('/financial_assistance/relationships', ''),
      method: "POST",
      dataType: 'script',
      cache: false,
      data: {
        "kind": $(this).val(),
        "applicant_id": $(this).data("applicant"),
        "relative_id": $(this).data("relative")
      }
    })
  });
})
