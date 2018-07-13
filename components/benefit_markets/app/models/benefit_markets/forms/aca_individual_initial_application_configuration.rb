module BenefitMarkets
  module Forms
    class AcaIndividualInitialApplicationConfiguration
      extend  ActiveModel::Naming
      
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations
      include Virtus.model

      attribute :pub_due_dom, Integer
      attribute :erlst_strt_prior_eff_months, Integer
      attribute :appeal_per_aft_app_denial_dys, Integer
      attribute :quiet_per_end, Integer
      # After submitting an ineligible plan year application, time period an Employer must wait
      attribute :inelig_per_aft_app_denial_dys, Integer
    end
  end
end