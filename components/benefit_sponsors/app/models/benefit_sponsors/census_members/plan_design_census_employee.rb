module BenefitSponsors
  module CensusMembers
    class PlanDesignCensusEmployee < BenefitSponsors::CensusMembers::CensusMember

      include AASM
      include Sortable
      include Searchable
      include Autocomplete

      EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
      EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)
      EMPLOYMENT_ACTIVE_ONLY = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked)
      COBRA_STATES = %w(cobra_eligible cobra_linked cobra_terminated cobra_termination_pending)

      field :is_business_owner, type: Boolean, default: false
      field :hired_on, type: Date
      field :aasm_state, type: String
      field :expected_selection, type: String, default: "enroll"
      field :employment_terminated_on, type: Date

      # field :employer_profile_id, type: BSON::ObjectId
      field :benefit_sponsorship_id, type: BSON::ObjectId

      has_many :census_survivors, class_name: "BenefitSponsors::CensusMembers::CensusSurvivor"
      embeds_many :census_dependents, as: :census_dependent, class_name: "BenefitSponsors::CensusMembers::CensusDependent",
                    cascade_callbacks: true,
                    validate: true
      accepts_nested_attributes_for :census_dependents

      embeds_many :benefit_group_assignments, as: :benefit_assignable, class_name: "BenefitSponsors::CensusMembers::BenefitGroupAssignment",
                    cascade_callbacks: true,
                    validate: true

      validates_presence_of :benefit_sponsorship_id, :dob

      validate :active_census_employee_is_unique
      validate :check_census_dependents_relationship
      validate :no_duplicate_census_dependent_ssns
      validate :check_hired_on_before_dob

      before_save :allow_nil_ssn_updates_dependents

      index({benefit_sponsorship_id: 1, ssn: 1}, {sparse: true})

      scope :by_benefit_sponsorship,  ->(benefit_sponsorship) { where(benefit_sponsorship_id: benefit_sponsorship._id) }

      # scope :by_sponsorship_id,       ->(benefit_sponsorship_id) { where(benefit_sponsorship_id: benefit_sponsorship_id) }
      # scope :by_employer_profile_id,  ->(employer_profile_id) { where(employer_profile_id: employer_profile_id) }

      scope :by_ssn,                  ->(ssn) { where(encrypted_ssn: BenefitSponsors::CensusMembers::CensusMember.encrypt_ssn(ssn)) }

      scope :active,            ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
      scope :terminated,        ->{ any_in(aasm_state: EMPLOYMENT_TERMINATED_STATES) }
      scope :by_cobra,          ->{ any_in(aasm_state: COBRA_STATES) }
      scope :active_alone,      ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_ONLY) }
      scope :expected_to_enroll,->{ where(expected_selection: 'enroll') }

      def initialize(*args)
        super(*args)
        write_attribute(:employee_relationship, "self")
      end

      def no_duplicate_census_dependent_ssns
        return if ssn.blank?
        dependents_ssn = census_dependents.map(&:ssn).select(&:present?)
        if dependents_ssn.uniq.length != dependents_ssn.length ||
          dependents_ssn.any?{|dep_ssn| dep_ssn==self.ssn}
          errors.add(:base, "SSN's must be unique for each dependent and subscriber")
        end
      end

      def active_census_employee_is_unique
        return if ssn.blank?
        potential_dups = self.class.where(benefit_sponsorship_id: benefit_sponsorship_id, ssn: ssn)
        # potential_dups = self.class.by_ssn(ssn).by_sponsorship_id(benefit_sponsorship_id)
        if potential_dups.detect { |dup| dup.id != self.id  }
          message = "Employee with this identifying information is already active. "\
          "Update or terminate the active record before adding another."
          errors.add(:base, message)
        end
      end

      def is_included_in_participation_rate?
        true
        # coverage_terminated_on.nil? ||
        # coverage_terminated_on >= active_benefit_group_assignment.start_on
      end

      def check_census_dependents_relationship
        return true if census_dependents.blank?

        relationships = census_dependents.map(&:employee_relationship)
        if relationships.count{|rs| rs=='spouse' || rs=='domestic_partner'} > 1
          errors.add(:census_dependents, "can't have more than one spouse or domestic partner.")
        end
      end

      def check_hired_on_before_dob
        if hired_on && dob && hired_on <= dob
          errors.add(:hired_on, "date can't be before  date of birth.")
        end
      end

      def is_eligible?
        ## Placeholder
        true
      end

      def allow_nil_ssn_updates_dependents
        census_dependents.each do |cd|
          if cd.ssn.blank?
            cd.unset(:encrypted_ssn)
          end
        end
      end

      def employer_profile=(new_employer_profile)
        raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile)
        self.employer_profile_id = new_employer_profile._id
        @employer_profile = new_employer_profile
      end

      def employer_profile
        return @employer_profile if defined? @employer_profile
        @employer_profile = benefit_sponsorship.benefit_sponsorable
      end

      def benefit_sponsorship=(benefit_sponsorship)
        raise ArgumentError.new("expected Benefit Sponsorship") unless benefit_sponsorship.is_a?(BenefitSponsors::BenefitSponsorships::BenefitSponsorship)
        self.benefit_sponsorship_id = benefit_sponsorship._id
        @benefit_sponsorship = benefit_sponsorship
      end

      def benefit_sponsorship
        return @benefit_sponsorship if defined? @benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(self.benefit_sponsorship_id)
      end

      def plan_design_proposal
        benefit_sponsorship.benefit_sponsorable.plan_design_proposal
      end

      def is_cobra_status?
        false
      end

      def expected_to_enroll?
        expected_selection == 'enroll'
      end

      def expected_to_enroll_or_valid_waive?
        %w(enroll waive).include?  expected_selection
      end

      def composite_rating_tier
        return ::CompositeRatingTier::EMPLOYEE_ONLY if self.census_dependents.empty?
        relationships = self.census_dependents.map(&:employee_relationship)
        if (relationships.include?("spouse") || relationships.include?("domestic_partner"))
          relationships.many? ? ::CompositeRatingTier::FAMILY : ::CompositeRatingTier::EMPLOYEE_AND_SPOUSE
        else
          ::CompositeRatingTier::EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS
        end
      end

      def self.to_csv

        columns = [
          "Family ID # (to match family members to the EE & each household gets a unique number)(optional)",
          "Relationship (EE, Spouse, Domestic Partner, or Child)",
          "Last Name",
          "First Name",
          "Middle Name or Initial (optional)",
          "Suffix (optional)",
          "Email Address",
          "SSN / TIN (Required for EE & enter without dashes)",
          "Date of Birth (MM/DD/YYYY)",
          "Gender",
          "Date of Hire",
          "Date of Termination (optional)",
          "Is Business Owner?",
          "Benefit Group (optional)",
          "Plan Year (Optional)",
          "Address Kind(Optional)",
          "Address Line 1(Optional)",
          "Address Line 2(Optional)",
          "City(Optional)",
          "State(Optional)",
          "Zip(Optional)"
        ]

        CSV.generate(headers: true) do |csv|
          csv << (["#{Settings.site.long_name} Employee Census Template"] +  6.times.collect{ "" } + [Date.new(2016,10,26)] + 5.times.collect{ "" } + ["1.1"])
          csv << %w(employer_assigned_family_id employee_relationship last_name first_name  middle_name name_sfx  email ssn dob gender  hire_date termination_date  is_business_owner benefit_group plan_year kind  address_1 address_2 city  state zip)
          csv << columns
          all.each do |census_employee|
            ([census_employee] + census_employee.census_dependents.to_a).each do |census_member|
              values = [
                census_member.employer_assigned_family_id,
                census_member.relationship_string,
                census_member.last_name,
                census_member.first_name,
                census_member.middle_name,
                census_member.name_sfx,
                census_member.email_address,
                census_member.ssn,
                census_member.dob.strftime("%m/%d/%Y"),
                census_member.gender
              ]

              if census_member.is_a?(BenefitSponsors::CensusMembers::PlanDesignCensusEmployee)
                values += [
                  census_member.hired_on.present? ? census_member.hired_on.strftime("%m/%d/%Y") : "",
                  census_member.employment_terminated_on.present? ? census_member.employment_terminated_on.strftime("%m/%d/%Y") : "",
                  census_member.is_business_owner ? "yes" : "no"
                ]
              else
                values += ["", "", "no"]
              end

              values += 2.times.collect{ "" }
              if census_member.address.present?
                values += census_member.address.to_a
              else
                values += 6.times.collect{ "" }
              end

              csv << values
            end
          end
        end
      end

      aasm do
        state :eligible, initial: true
        state :cobra_eligible
        state :newly_designated_eligible
        state :employee_role_linked
        state :cobra_linked
        state :newly_designated_linked
        state :cobra_termination_pending
        state :employee_termination_pending
        state :employment_terminated
        state :cobra_terminated
        state :rehired
      end

      class << self

        def find(id)
          unscoped.where(id: BSON::ObjectId.from_string(id)).first
        end

        def find_by_benefit_sponsor(sponsor)
          unscoped.where(benefit_sponsorship_id: sponsor._id).order_name_asc
        end

        def find_all_by_benefit_group(benefit_group)
          unscoped.where("benefit_group_assignments.benefit_group_id" => benefit_group._id)
        end

        def find_all_by_employer_profile(employer_profile)
          unscoped.where(employer_profile_id: employer_profile._id).order_name_asc
        end

        alias_method :find_by_employer_profile, :find_all_by_employer_profile
      end
    end
  end
end
