module Insured::PlanFilterHelper
  include Config::SiteHelper
  include L10nHelper

  def find_my_doctor
    if @market_kind == "individual"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dc/', target: '_blank')
    elsif @market_kind == "shop"
      link_to('Find Your Doctor', find_your_doctor_url , target: '_blank')
    end
  end

  def estimate_your_costs
    if @market_kind == "shop" && @coverage_kind == "health"
      link_to(l10n("estimate_your_costs"), @dc_checkbook_url , target: '_blank')
    end
  end

end
