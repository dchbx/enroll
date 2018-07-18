function initPlanOptions(plan_options, location_id) {  
   $('.reference-plans').html("<div class='col-xs-12 health select-reference'><br><br><h1 class='row'>Select Your Reference Plan</h1><h4 style='position: relative;' class='row'><span class='starter' style='display: inline-block;'>Now select a reference plan. The reference plan is used to cap employer costs. You’ll choose a reference plan. Then, your contribution towards employee premiums will be applied to the reference plan you choose regardless of which plans your employees select. After you select your reference plan, scroll down to review your costs.</span><span style='position: absolute; right: 0; bottom: 0;'>Displaying: <strong>" + plan_options.length + "Plans</strong> </span></h4><br/></div>");

   $.each(plan_options, function (index, product) {

      var productHtml = '<div class="col-xs-4">\
        <div class="col-xs-12 reference-plan">\
          <div class="col-xs-2">\
            <input type="radio" value="' + product["id"] + '" name="benefit_package[sponsored_benefits_attributes][0][reference_plan_id]">\
            <label for="' + location_id + '_reference_plan_id">\
              <i class="fa fa-circle-o"></i>\
              <i class="fa fa-dot-circle-o"></i>\
            </label>\
          </div>\
          <div class="col-xs-10">\
            <div class="panel row">\
              <div class="panel-heading">\
                <h3>' + product["title"] + '</h3>\
              </div>\
              <div class="panel-body">\
                <span class="plan-label">Type: </span><span>' + product["coverage_kind"] + '</span><br>\
                <span class="plan-label">Carrier: </span><span>' + product["carrier_name"] + '</span><br>\
                <span class="plan-label">Level: </span><span>' + product["metal_level_kind"] + '</span><br>\
              </div>\
            </div>\
          </div>\
        </div>\
      </div>'

      $('.reference-plans').append(productHtml);
    });
  
    $('.reference-plans').css({ "height": "450px", "y-overflow": "scroll" });
    $('.reference-plans').show();
};


