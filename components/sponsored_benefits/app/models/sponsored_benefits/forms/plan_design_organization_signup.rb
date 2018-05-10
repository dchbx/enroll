module SponsoredBenefits
  module Forms
    class PlanDesignOrganizationSignup
      include ActiveModel::Validations

      attr_accessor :legal_name, :dba, :entity_kind, :fein, :is_fake_fein, :sic_code
      attr_accessor :office_locations
      attr_accessor :contact_method

      validates_presence_of :legal_name, :sic_code
      validate :office_location_validations
      validate :office_location_kinds

      def initialize(attrs = {})
        @office_locations ||= []
        assign_wrapper_attributes(attrs)
        ensure_office_locations
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def to_key
        @id
      end

      def ensure_office_locations
        if @office_locations.empty?
          new_office_location = SponsoredBenefits::Organizations::OfficeLocation.new
          new_office_location.build_address
          new_office_location.build_phone
          @office_locations = [new_office_location]
        end
      end

      def office_location_validations
        @office_locations.each_with_index do |ol, idx|
          ol.valid?
          ol.errors.each do |k, v|
            self.errors.add("office_locations_attributes.#{idx}.#{k}", v)
          end
        end
      end

      def office_location_kinds
        location_kinds = self.office_locations.flat_map(&:address).flat_map(&:kind)

        if location_kinds.count('primary').zero?
          self.errors.add(:base, "must select one primary address")
        elsif location_kinds.count('primary') > 1
          self.errors.add(:base, "can't have multiple primary addresses")
        elsif location_kinds.count('mailing') > 1
          self.errors.add(:base, "can't have more than one mailing address")
        end
      end

      def office_locations_attributes
        @office_locations.map do |office_location|
          office_location.attributes
        end
      end

      def office_locations_attributes=(attrs)
        @office_locations = []
        attrs.each_pair do |k, att_set|
          @office_locations << SponsoredBenefits::Organizations::OfficeLocation.new(att_set)
        end
        @office_locations
      end

    end
  end
end