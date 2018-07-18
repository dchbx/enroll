# Organization type with strict data entry/validation policies used for S-Corp, C-Corp, LLC and similar where FEIN is assigned
module BenefitSponsors
  module Organizations
    class GeneralOrganization < BenefitSponsors::Organizations::Organization

      # validates_presence_of :entity_kind, :legal_name

      # validates :entity_kind,
      #   inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid entity kind" },
      #   allow_blank: false

      validates_presence_of :legal_name

      validates :entity_kind,
        inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
        allow_blank: false

      validates :fein,
        presence: true,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true,
        uniqueness: true


    end
  end
end
