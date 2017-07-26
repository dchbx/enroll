$('#show_profile').html("<%= escape_javascript render("show_profile") %>")
$('.fade').addClass('in').addClass('active')
$('#inbox').removeClass('active').removeClass('in')
semantic_class();
$('#show_profile').removeClass('hide')


$('div[name=employee_family_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      search = $("#census_employee_search input#employee_search").val();
      $('#employees_' + filter).siblings().hide();
      $('#employees_' + filter).show();
      $.ajax({
        url: $('span[name=employee_families_url]').text() + '.js',
        type: "GET",
        data : { 'status': filter, 'employee_search': search }
      });

      $('#status').val(filter);
    })
  })
