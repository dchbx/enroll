# Organization type with relaxed data entry/validation policies used for government agencies, 
# embassies and other types where FEIN is not assigned/available
module BenefitSponsors
  module Organizations
    class Organization
      include Mongoid::Document

      # field :hbx_id, type: String

      # field :home_page, type: String

      field :legal_name, type: String
      field :dba, type: String
      field :entity_kind, type: Symbol
      field :fein, type: String


      belongs_to  :site, inverse_of: :site_organizations, counter_cache: true,
        class_name: "BenefitSponsors::Site"

      belongs_to  :site_owner, inverse_of: :owner_organization,
                  class_name: "BenefitSponsors::Site"

    end
  end
end
