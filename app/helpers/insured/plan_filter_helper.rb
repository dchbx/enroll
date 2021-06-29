# frozen_string_literal: true

module Insured
  module PlanFilterHelper
    include L10nHelper

    def find_my_doctor
      if @market_kind == "individual" && @coverage_kind == "health"
        link_to('Find Your Doctor','',data: {toggle: "modal", target: "#plan_match_family"})
      elsif (@market_kind == "shop" || @market_kind == 'fehb') && @coverage_kind == "health"
        # link_to('Find Your Doctor', Rails.application.config.checkbook_services_base_url + '/dcshopnationwide/', target: '_blank')
        link_to('Find Your Doctor','',data: {toggle: "modal", target: "#plan_match_doctor_shop"})
      end
    end

    def estimate_your_costs
      link_to(l10n("estimate_your_costs"),'',data: {toggle: "modal", target: "#plan_match_shop"}) if (@market_kind == "shop" || @market_kind == 'fehb') && @coverage_kind == "health" && @dc_checkbook_url != false
    end
  end
end