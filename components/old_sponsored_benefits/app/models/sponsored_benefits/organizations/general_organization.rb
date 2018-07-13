# Organization type with strict data entry/validation policies used for S-Corp, C-Corp, LLC and similar where FEIN is assigned
module SponsoredBenefits
  module Organizations
    class GeneralOrganization < Organization

      # Federal Employer ID Number
      field :fein, type: String

      validates_presence_of :entity_kind, :legal_name

      validates :fein,
        presence: true,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true,
        uniqueness: true


    end
  end
end
