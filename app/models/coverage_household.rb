class CoverageHousehold
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include HasFamilyMembers

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household

  # all coverage_household members are immediate relations
  field :is_immediate_family, type: Boolean

  # coverage household includes immediate relations with non-QHP eligibility determination 
  field :is_determination_split_household, type: Boolean, default: false

  # Agency representing this coverage household
  field :broker_agency_id, type: BSON::ObjectId

  # Broker agent credited for enrollment and transmitted on 834
  field :writing_agent_id, type: BSON::ObjectId

  field :aasm_state, type: String, default: "applicant"
  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members, cascade_callbacks: true
  accepts_nested_attributes_for :coverage_household_members, allow_destroy: true

  validates_presence_of :is_immediate_family
  validate :presence_of_coverage_household_members

  embeds_many :workflow_state_transitions, as: :transitional

  # belongs_to writing agent (broker_role)
  def writing_agent=(new_writing_agent)
    raise ArgumentError.new("expected BrokerRole class") unless new_writing_agent.is_a? BrokerRole
    self.new_writing_agent_id = new_writing_agent._id
    @writing_agent = new_writing_agent
  end

  def writing_agent
    return @writing_agent if defined? @writing_agent
    @writing_agent = BrokerRole.find(self.writing_agent_id) unless writing_agent_id.blank?
  end

  # belongs_to BrokerAgencyProfile
  def broker_agency_profile=(new_broker_agency)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency.is_a? BrokerAgencyProfile
    self.broker_agency_id = new_broker_agency._id
    @broker_agency_profile = new_broker_agency
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(self.broker_agency_id) unless broker_agency_id.blank?
  end

  def subscriber
    coverage_household_members.detect(&:is_subscriber)
  end

  def family
    return nil unless household
    household.family
  end

  def applicant_ids
    coverage_household_members.map(&:family_member_id)
  end

  def add_coverage_household_member(family_member)
    return if coverage_household_members.where(family_member_id: family_member.id).present?

    coverage_household_members.build(
      family_member: family_member,
      is_subscriber: family_member.is_primary_applicant?
    )


    # chm.save_parent
    # household.save
  end

  def remove_family_member(family_member)
    coverage_household_members.where(family_member_id: family_member.id).each do |chm|
      chm.destroy
    end

    # if chm = coverage_household_members.first
    #   chm.reload
    #   chm.save_parent
    # end

    # household.save
  end

  def remove_coverage_household_member(coverage_household_member_id, family_member_id)
    chm = coverage_household_members.where(id: coverage_household_member_id).and(family_member_id: family_member_id).first
    chm.destroy if !chm.nil?
  end

  def notify_the_user(member)
    if member.person && (role = member.person.consumer_role)
      if role.is_hbx_enrollment_eligible? && role.identity_verified_date
        IvlNotificationMailer.lawful_presence_verified(role)
      elsif role.is_hbx_enrollment_eligible? && role.identity_verification_pending?
        IvlNotificationMailer.lawful_presence_unverified(role)
      elsif !role.is_hbx_enrollment_eligible?
        IvlNotificationMailer.lawfully_ineligible(role)
      end
    end
  end

  aasm do
    state :unverified, initial: true
    state :enrollment_submitted
    state :enrolled_contingent
    state :enrolled
    state :canceled
    state :terminated

    event :move_to_contingent!, :after => :record_transition do
      transitions from: :terminated, to: :terminated
      transitions from: :canceled, to: :canceled
      transitions from: :unverified, to: :enrolled_contingent, after: :notify_verification_outstanding
      transitions from: :enrollment_submitted, to: :enrolled_contingent, after: :notify_verification_outstanding
      transitions from: :enrolled_contingent, to: :enrolled_contingent
      transitions from: :enrolled, to: :enrolled_contingent, after: :notify_verification_outstanding
    end

    event :move_to_enrolled!, :after => :record_transition do
      transitions from: :terminated, to: :terminated
      transitions from: :canceled, to: :canceled
      transitions from: :unverified, to: :enrolled, after: :notify_verification_success
      transitions from: :enrolled_contingent, to: :enrolled, after: :notify_verification_success
      transitions from: :enrolled, to: :enrolled
      transitions from: :enrollment_submitted, to: :enrolled, after: :notify_verification_success
    end

    event :move_to_pending!, :after => :record_transition do
      transitions from: :terminated, to: :terminated
      transitions from: :canceled, to: :canceled
      transitions from: :unverified, to: :unverified
      transitions from: :enrolled_contingent, to: :unverified
      transitions from: :enrolled, to: :unverified
      transitions from: :enrollment_submitted, to: :unverified
    end
  end

  def self.update_individual_eligibilities_for(consumer_role)
    found_families = Family.find_all_by_person(consumer_role.person)
    found_families.each do |ff|
      ff.households.each do |hh|
        hh.coverage_households.each do |ch|
          ch.evaluate_individual_market_eligiblity
        end
        hh.hbx_enrollments.each do |he|
          he.evaluate_individual_market_eligiblity
        end
      end
    end
  end

  def evaluate_individual_market_eligiblity
    eligibility_ruleset = ::RuleSet::CoverageHousehold::IndividualMarketVerification.new(self)
    if eligibility_ruleset.applicable?
      self.send(eligibility_ruleset.determine_next_state)
    end
  end

  def active_individual_enrollments
    household.hbx_enrollments.select do |he|
      (he.coverage_household_id == self.id.to_s) &&
         (!he.benefit_sponsored?) &&
         he.currently_active?
    end
  end

  def notify_verification_outstanding
  end

  def notify_verification_success
  end

private
  def presence_of_coverage_household_members
    if self.coverage_household_members.size == 0 && is_immediate_family
      self.errors.add(:base, "Should have at least one coverage_household_member")
    end
  end

  def record_transition(*args)
    workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end

end
