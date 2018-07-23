module BenefitSponsors
  module Forms
    class ExemptOrganization
      extend ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      include Virtus.model

      attribute :id, String
      attribute :legal_name, String
      attribute :profile, BenefitSponsors::Forms::HbxProfile

      def profile_attributes=(profile)
        self.profile = BenefitSponsors::Forms::HbxProfile.new(profile)
      end
    end
  end
end
