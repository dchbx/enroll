module SponsoredBenefits
  module Forms
    class CensusMember
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :first_name, :middle_name, :last_name, :name_sfx, :ssn, :gender, :dob, :employee_relationship

      attr_reader :address
      attr_reader :email
      attr_reader :census_dependents

      validates_presence_of :first_name, :last_name, :dob, :employee_relationship

      def initialize(attrs = {})
        assign_wrapper_attributes(attrs)
        ensure_address
        ensure_email
        ensure_dependents
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def addresss=(attrs)
      end

      def email=(attrs)
      end

      def ensure_dependents
        @census_dependents = []
      end

      def ensure_address
        @address ||= SponsoredBenefits::Locations::Address.new
      end

      def ensure_email
        @email ||= SponsoredBenefits::Email.new
      end
    end
  end
end
