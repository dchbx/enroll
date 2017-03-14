window.Remote =
  findSepLink: (path) ->
    if $("#find_sep_link").length > 0
      $("#find_sep_link").click ->
        $(this).closest('form').attr('action', path);
        $(this).closest('form').attr('method', 'get');
        $(this).closest('form').submit()

  setGroupSelectionHandlers: (can_shop_markets, can_shop_shop, market_kind, no_active_benefit_group, is_offering_dental) ->
    $('.group-selection-table .dental input').removeProp('checked');
    if($('#market_kind_shop').is(':checked') )
      $("#coverage_kind_health").prop("checked", true)
      $("#ivl-coverage-household input[type=checkbox]").prop("checked", false)

    if can_shop_markets == true
      if market_kind == 'individual'
        $('#market_kind_individual').prop("checked", true)
        $('#dental-radio-button').show()

      $(document).on 'change', '#market_kind_shop', ->
        if((no_active_benefit_group == true) and (is_offering_dental == false))
          $('#dental-radio-button').slideUp()
        $('#shop-coverage-household').show()
        $('#ivl-coverage-household').hide()
        $('#ivl-coverage-household input').removeProp('checked')
        $('#shop-coverage-household .health tr').not(".ineligible_row").find('input').prop('checked', 'checked') if($('#coverage_kind_health').is(':checked'))
        $('#shop-coverage-household .dental tr').not(".ineligible_row").find('input').prop('checked', 'checked') if($('#coverage_kind_dental').is(':checked'))

      $(document).on 'change', '#market_kind_individual', ->
        $('#dental-radio-button').slideDown()
        $('#ivl-coverage-household').show()
        $('#shop-coverage-household').hide()
        $('#shop-coverage-household input').removeProp('checked')
        $('#ivl-coverage-household tr').not(".ineligible_row").find('input').prop('checked', 'checked')

    if((can_shop_shop and can_shop_markets) and ((no_active_benefit_group == false) and (is_offering_dental == true)))
      $(document).on 'change', '#coverage_kind_health', ->
        $('#shop-coverage-household .health').show()
        $('#shop-coverage-household .health tr').not(".ineligible_row").find('input').prop('checked', 'checked')
        $('#shop-coverage-household .dental').hide()
        $('#shop-coverage-household .dental input').removeProp('checked')

        $(document).on 'change', '#coverage_kind_dental', ->
          $('#shop-coverage-household .dental').show()
          $('#shop-coverage-household .dental tr').not(".ineligible_row").find('input').prop('checked', 'checked')
          $('#shop-coverage-household .health').hide()
          $('#shop-coverage-household .health input').removeProp('checked')

    $(document).on 'change', 'input[type="checkbox"]', ->
      if ($("#coverage_kind_health").is(":checked"))
        if($(this).is(":checked"))
          $(this).attr( "checked", true )
        else
          $(this).removeProp('checked')
          $('#shop-coverage-household .dental input').removeProp('checked')