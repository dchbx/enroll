// $('.effective-datatable').DataTable().draw()


$('.quotes-data-table').next('.container').html('');
$('.quotes-data-table').html("<%= escape_javascript(render "quotes") %>");
semantic_class()
initializeDataTables();
