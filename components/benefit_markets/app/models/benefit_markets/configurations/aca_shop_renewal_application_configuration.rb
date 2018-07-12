module BenefitMarkets
  module Configurations
    # AcaShopRenewalApplicationConfiguration settings
    class AcaShopRenewalApplicationConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :configuration, class_name: "BenefitMarkets::Configurations::AcaShopConfiguration"

      field :erlst_strt_prior_eff_months, as: :earliest_start_prior_to_effective_on_months, type: Integer, default: -3
      field :montly_oe_end, as: :monthly_open_enrollment_end_on, type: Integer, default: 13
      field :pub_due_dom, as: :publish_due_day_of_month, type: Integer, default: 10
      field :force_pub_dom, as: :force_publish_day_of_month, type: Integer, default: 11
      field :oe_min_dys, as: :open_enrollment_minimum_days, type: Integer, default: 3
      field :quiet_per_end, as: :quiet_period_end_on, type: Integer, default: 15

      validates_presence_of :erlst_strt_prior_eff_months, :montly_oe_end, :pub_due_dom, :force_pub_dom, :oe_min_dys, :quiet_per_end
    end
  end
end
