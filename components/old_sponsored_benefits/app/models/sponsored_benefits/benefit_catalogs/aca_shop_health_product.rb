module SponsoredBenefits
  module BenefitCatalogs
    class AcaShopHealthProduct < Product
      include Mongoid::Document
      include Mongoid::Timestamps  

      FILTERS   = {   metal_level:  [:platinum, :gold, :silver, :bronze],
                      plan_type:    [:hmo, :ppo, :pos, :epo],
                      service_area: [:local, :national]
                    }


      field :metal_level,     type: String

      field :hios_id,         type: String
      field :hios_base_id,    type: String
      field :csr_variant_id,  type: String

      field :provider_directory_url,  type: String
      field :rx_formulary_url,        type: String


      embeds_one :sbc_document, :class_name => "Document", as: :documentable


    end
  end
end
