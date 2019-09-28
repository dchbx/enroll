module BenefitMarkets
  module Configurations
    class AcaShopRenewalApplicationConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :configuration, class_name: "BenefitMarkets::Configurations::AcaShopConfiguration"

      field :erlst_strt_prior_eff_months, as: :earliest_start_prior_to_effective_on_months, type: Integer, default: -2
      field :erlst_strt_prior_eff_dom,    as: :earliest_start_prior_to_effective_day_of_month, type: Integer, default: 0
      field :montly_oe_end,               as: :monthly_open_enrollment_end_on, type: Integer, default: 20
      field :pub_due_dom,                 as: :publish_due_day_of_month, type: Integer, default: 15
      field :force_pub_dom,               as: :force_publish_day_of_month, type: Integer, default: 16
      field :oe_min_dys,                  as: :open_enrollment_minimum_days, type: Integer, default: 5
      field :app_sub_soft_dline,          as: :application_submission_soft_deadline, type: 10
      field :quiet_per_end_mth_offset,    as: :quiet_period_end_month_offset, type: Integer, default: -1
      field :quiet_per_end_dom,           as: :quiet_period_end_day_of_month, type: Integer, default: 26 

      validates_presence_of :erlst_strt_prior_eff_months, :erlst_strt_prior_eff_dom, :montly_oe_end, :pub_due_dom, :force_pub_dom, :oe_min_dys, :app_sub_soft_dline, :quiet_per_end_mth_offset, :quiet_per_end_dom
    end
  end
end
