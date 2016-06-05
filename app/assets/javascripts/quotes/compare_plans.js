
selected_plans = function(){
  var plans=[];
  $.each($('.btn.active input'), function(i,item){plans.push( $(item).attr("value"))})
  return(plans)
}

sort_plans = function(){
      var sort_by = $(this.parentNode).text();
      var plans = selected_plans()
      if(plans.length == 0) {
        alert('Please select one or more plans for comparison');
        return;
      }
      $.ajax({
        type: "GET",
        url: "/broker_agencies/quotes/plan_comparison",
        data: {plans: plans, sort_by: sort_by.substring(0, sort_by.length-2)},
        success: function(response) {
          $('#plan_comparison_frame').html(response);
          compare_plans_listeners();
          collapse_all()
        }
      })
    }
compare_plans_listeners = function (){
    $('#compare_plans_table').dragtable({dragaccept: '.movable'});
    $('.cost_sort').on('click', sort_plans);
}