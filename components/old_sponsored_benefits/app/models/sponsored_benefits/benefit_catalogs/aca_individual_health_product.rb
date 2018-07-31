module SponsoredBenefits
  class BenefitCatalogs::AcaIndividualHealthProduct
    include Mongoid::Document

      FILTERS   = {   metal_level:  [:platinum, :gold, :silver, :bronze, :catastrophic],
                      plan_type:    [:hmo, :ppo, :pos, :epo],
                      service_area: [:local, :national]
                    }


      field :hios_id,           type: String
      field :hios_base_id,      type: String
      field :metal_level,       type: String
      field :csr_variant_id,    type: String
      field :ehb, as: :essential_health_benefit_pct, type: Float, default: 0.0
      field :cat_age_off_renewal_plan_id, type: BSON::ObjectId
      field :is_standard_plan, type: Boolean, default: false


      embeds_one :sbc_document, :class_name => "Document", as: :documentable



  end
end
