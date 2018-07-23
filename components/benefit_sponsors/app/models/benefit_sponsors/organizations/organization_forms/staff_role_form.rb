module BenefitSponsors
  module Organizations
    class OrganizationForms::StaffRoleForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :npn, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :email, String
      attribute :phone, String
      attribute :status, String
      attribute :dob, String
      attribute :person_id, String
      attribute :area_code, String
      attribute :number, String
      attribute :extension, String
      attribute :profile_id, String

      attribute :profile_type, String

      validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }

      validates :area_code, :if => Proc.new { |m| m.area_code.present? },
                numericality: true,
                length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
                allow_blank: false

      validates :number,:if => Proc.new { |m| m.number.present? },
                numericality: true,
                length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
                allow_blank: false

      def persisted?
        false
      end

      def first_name=(val)
        @first_name = val.blank? ? nil : val.strip
      end

      def last_name=(val)
        @last_name = val.blank? ? nil : val.strip
      end

      def dob=(val)
        #TODO refactor according to the date format
        begin
          (val.split('-').first.size == 4) ? @dob = Date.strptime(val,"%Y-%m-%d") : @dob = Date.strptime(val,"%m/%d/%Y")
          return @dob
        rescue
          return nil
        end
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end

      # for new
      def self.for_new
        self.new
      end

      # for create
      def self.for_create(attrs)
        new(attrs)
      end

      def save
        persist!
      end

      def persist!
        return false unless valid?
        service.add_profile_representative!(self)
      end

      # for approve
      def self.for_approve(attrs)
        new(attrs)
      end

      def approve
        approve!
      end

      def approve!
        return false unless valid?
        service({profile_id: profile_id}).approve_profile_representative!(self)
      end

      # for destroy
      def self.for_destroy(attrs)
        new(attrs)
      end

      def destroy
        destroy!
      end

      def destroy!
        return false unless valid?
        service({profile_id: profile_id}).deactivate_profile_representative!(self)
      end


      protected

      def self.resolve_service(attrs ={})
        Services::StaffRoleService.new(attrs)
      end

      def service(attrs={})
        return @service if defined?(@service)
        @service = self.class.resolve_service
      end
    end
  end
end
