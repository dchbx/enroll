module BenefitMarkets
  module Configurations
    # AcaShopInitialApplicationConfiguration settings
    class AcaShopInitialApplicationConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :configuration, class_name: "BenefitMarkets::Configurations::AcaShopConfiguration"

      field :pub_due_dom, as: :publish_due_day_of_month, type: Integer, default: 15
      field :adv_pub_due_dom, as: :advertised_deadline_of_month, type: Integer, default: 10
      field :erlst_strt_prior_eff_months, as: :earliest_start_prior_to_effective_on_months, type: Integer, default: -2
      field :appeal_per_aft_app_denial_dys, as: :appeal_period_after_app_denial_days, type: Integer, default: 30
      field :quiet_per_end, as: :quiet_period_end_on, type: Integer, default: 28
      # After submitting an ineligible plan year application, time period an Employer must wait
      field :inelig_per_aft_app_denial_dys, as: :ineligible_period_after_application_denial_days, type: Integer, default: 90

      validates_presence_of :pub_due_dom, :erlst_strt_prior_eff_months, :appeal_per_aft_app_denial_dys, :quiet_per_end, :inelig_per_aft_app_denial_dys
    end
  end
end