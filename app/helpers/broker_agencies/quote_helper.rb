module BrokerAgencies::QuoteHelper

  def draft_quote_header(state,quote_name)
    if state == "draft"
      content_tag(:h3, "Review: Publish your #{quote_name}" )+
      content_tag(:span, "Please review the information below before publishing your quote. Once the quote is published, no information can be changed.")
    end
  end

  def display_dental_plan_option_kind(bg)
    kind = bg.dental_plan_option_kind
    if kind == 'single_carrier'
      fetch_plan_title_for_single_carrier
    else
      'Custom'
    end
  end

  def get_health_cost_comparison(options={})
    @qbg = options[:benefit_id].present? && options[:quote_id].present? ? Quote.find(params[:quote_id]).quote_benefit_groups.find(params[:benefit_id]) : options[:benefit_group]
    @quote_results = Hash.new
    @health_plans = Plan.shop_health_plans @qbg.quote.plan_year
    unless @qbg.nil?
      roster_premiums = @qbg.roster_cost_all_plans
      @roster_elected_plan_bounds = PlanCostDecoratorQuote.elected_plans_cost_bounds(@health_plans,
      @qbg.quote_relationship_benefits, roster_premiums)
      elected_health_plan_ids = options[:plan_ids].present? ? options[:plan_ids] : @qbg.elected_health_plan_ids
      elected_health_plan_ids.each do |plan_id|
        p = @health_plans.detect{|plan| plan.id.to_s == plan_id.to_s}
        detailCost = Array.new
        @qbg.quote_households.each do |hh|
          pcd = PlanCostDecoratorQuote.new(p, hh, @qbg, p)
          detailCost << pcd.get_family_details_hash(@qbg.quote.start_on).sort_by { |m|
           [m[:family_id], -m[:age], -m[:employer_contribution]]
          }
        end
        employer_cost = @qbg.roster_employer_contribution(p,p)
        @quote_results[p.name] = {:detail => detailCost,
          :total_employee_cost => @qbg.roster_employee_cost(p),
          :total_employer_cost => employer_cost,
          plan_id: plan_id,
          buy_up: PlanCostDecoratorQuote.buy_up(employer_cost, p.metal_level, @roster_elected_plan_bounds)
        }
      end
    end
    @quote_results = @quote_results.sort_by { |k, v| v[:total_employer_cost] }.to_h
  end

  def get_dental_cost_comparison(options={})
    @qbg = options[:benefit_id].present? && options[:quote_id].present? ? Quote.find(params[:quote_id]).quote_benefit_groups.find(params[:benefit_id]) : options[:benefit_group]
    @quote_results = Hash.new
    @health_plans = Plan.shop_dental_plans(@qbg.quote.plan_year)
    @roster_elected_plan_bounds = PlanCostDecoratorQuote.elected_plans_cost_bounds(
      @health_plans,
      @qbg.quote_dental_relationship_benefits,
      @qbg.roster_cost_all_plans('dental'))
    elected_dental_plan_ids = options[:plan_ids].present? ? options[:plan_ids] : @qbg.elected_dental_plan_ids
    elected_dental_plan_ids.each do |plan_id|
      p = @health_plans.detect{|plan| plan.id.to_s == plan_id.to_s}
      detailCost = Array.new
      @qbg.quote_households.each do |hh|
        pcd = PlanCostDecoratorQuote.new(p, hh, @qbg, p)
        detailCost << pcd.get_family_details_hash(@qbg.quote.start_on).sort_by { |m| [m[:family_id], -m[:age], -m[:employer_contribution]] }
      end

      employer_cost = @qbg.roster_employer_contribution(p,p)
      @quote_results[p.name] = {:detail => detailCost,
        :total_employee_cost => @qbg.roster_employee_cost(p),
        :total_employer_cost => employer_cost,
        plan_id: plan_id,
      }
    end
    @quote_results = @quote_results.sort_by { |k, v| v[:total_employer_cost] }.to_h
  end

end