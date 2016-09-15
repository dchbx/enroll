var QuoteSliders = (function() {
  var slider_listeners = function() {
  $(document).on('keyup', 'input.slider_input, input.right_slider_input', function() {
    if($(this).val() > 100) {
      if(['ex1_input','ex2_input'].includes($(this).attr('id'))) {
        if($(this).val() > 6000) {
          $(this).val(6000);
        }
      }
      else {
        $(this).val(100);
      }
    }
    if ( $(this).hasClass('slider_input') )  {
      var hidden = parseInt($(this).val());
      if(isNaN(hidden)) {
        hidden = 0;
      }
      if ( $(this).hasClass('right_slider_input') ) {
        var mySlider = $(this).closest('div.row').find('input.slider').eq(1);
        mySlider.bootstrapSlider('setValue', hidden);
        mySlider.attr('value', hidden).attr('data-slider-value', hidden);
        $(this).closest('div.row').find('.slide-label').eq(1).text(hidden + "%");
      }
      else {
        var mySlider = $(this).closest('div.row').find('input.slider').eq(0);
        mySlider.bootstrapSlider('setValue', hidden);
        mySlider.attr('value', hidden).attr('data-slider-value', hidden);
        if(['ex1_input','ex2_input'].includes($(this).attr('id'))) {
          $(this).closest('div.row').find('.slide-label').eq(0).text("$" + hidden);
        }
        else {
          $(this).closest('div.row').find('.slide-label').eq(0).text(hidden + "%");
        }
      }
    }
  });

  $(document).on('change', 'input.slider, input.right-slider', function(){
    if ($(this).hasClass('slider')) {
      var data = $(this).val();
      if ( $(this).hasClass('right-slider') ) {
        $(this).on("slideStop", function(slideEvt) {
          $(this).closest('div.row').find('.slider_input').eq(1).val(data);
          $(this).closest('div.row').find('.slide-label').eq(1).text(data + "%");
        });
      }
      else {
        $(this).on("slideStop", function(slideEvt) {
          $(this).closest('div.row').find('input').eq(0).val(data);
          if(['ex1','ex2'].includes($(this).attr('id'))) {
            $(this).closest('div.row').find('.slide-label').eq(0).text("$" + data);
          }
          else {
            $(this).closest('div.row').find('.slide-label').eq(0).text(data + "%");
          }
        });
      }
    }
  });


      $('#ex1').bootstrapSlider({});
      $('#ex2').bootstrapSlider({});
      $('#total_plan_cost').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#pct_employee').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#pct_spouse').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#pct_domestic_partner').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#pct_child_under_26').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#dental_pct_employee').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#dental_pct_spouse').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#dental_pct_domestic_partner').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#dental_pct_child_under_26').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });
      $('#dental_pctemployees_on_roster').bootstrapSlider({
        formatter: function(value) {
          return 'Contribution Percentage: ' + value + '%';
        }
      });

      $('#ex1').on('slideStop', function(){deductible_value = this.value;
        QuotePageLoad.toggle_plans([]);
        QuotePageLoad.reset_selected_plans();
      })
      $('#pct_employee').on('slideStop', function() {
        val =$('#pct_employee').bootstrapSlider('getValue')
        QuotePageLoad.set_relationship_pct('employee', val)
      })
      $('#dental_pct_employee').on('slideStop', function() {
        val =$('#dental_pct_employee').bootstrapSlider('getValue')
        QuotePageLoad.set_dental_relationship_pct('employee', val)
      });
      $('#dental_pct_spouse').on('slideStop', function() {
        val =$('#dental_pct_spouse').bootstrapSlider('getValue')
        QuotePageLoad.set_dental_relationship_pct('spouse', val)
      });
      $('#dental_pct_spouse').on('slideStop', function() {
        val =$('#dental_pct_spouse').bootstrapSlider('getValue')
        QuotePageLoad.set_dental_relationship_pct('spouse', val)
      })
      $('#dental_pct_domestic_partner').on('slideStop', function() {
            val =$('#dental_pct_domestic_partner').bootstrapSlider('getValue')
            QuotePageLoad.set_dental_relationship_pct('domestic_partner', val)
      });
      $('#dental_pct_child_under_26').on('slideStop', function() {
            val =$('#dental_pct_child_under_26').bootstrapSlider('getValue')
            QuotePageLoad.set_dental_relationship_pct('child_under_26', val)
      });
      $('#employee_slide_input').on('keyup', function() {
        setTimeout(function () {
          QuotePageLoad.set_relationship_pct('employee', $('#employee_slide_input').val())
        }, 700);
      });
      $('#pct_spouse').on('slideStop', function() {
            val =$('#pct_spouse').bootstrapSlider('getValue')
            QuotePageLoad.set_relationship_pct('spouse', val)
           })
     $('#spouse_input').on('keyup', function() {
       setTimeout(function () {
         val =$('#pct_spouse').bootstrapSlider('getValue')
         QuotePageLoad.set_relationship_pct('spouse', val)
       }, 700);
     });
      $('#pct_domestic_partner').on('slideStop', function() {
            val =$('#pct_domestic_partner').bootstrapSlider('getValue')
            QuotePageLoad.set_relationship_pct('domestic_partner', val)
           })
     $('#domestic_input').on('keyup', function() {
       setTimeout(function () {
         val =$('#pct_domestic_partner').bootstrapSlider('getValue')
         QuotePageLoad.set_relationship_pct('domestic_partner', val)
       }, 700);
     });
      $('#pct_child_under_26').on('slideStop', function() {
            val =$('#pct_child_under_26').bootstrapSlider('getValue')
            QuotePageLoad.set_relationship_pct('child_under_26', val)
           })
     $('#child_input').on('keyup', function() {
       setTimeout(function () {
         val =$('#pct_child_under_26').bootstrapSlider('getValue')
         QuotePageLoad.set_relationship_pct('child_under_26', val)
       }, 700);
     });
  }
  return {
    slider_listeners: slider_listeners,
  }
})();