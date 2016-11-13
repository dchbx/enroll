require 'autoinc'

class Family
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Sortable
  include Mongoid::Autoinc

  field :version, type: Integer, default: 1
  embeds_many :versions, class_name: self.name, validate: false, cyclic: true, inverse_of: nil

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  ImmediateFamily = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter}

  field :hbx_assigned_id, type: Integer

  increments :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String # Eligibility system foreign key
  field :e_status_code, type: String
  field :application_type, type: String
  field :renewal_consent_through_year, type: Integer # Authorize auto-renewal elibility check through this year (CCYY format)

  field :is_active, type: Boolean, default: true # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime # Date application was created on authority system
  field :updated_by, type: String
  field :status, type: String, default: "" # for aptc block

  before_save :clear_blank_fields
 #after_save :generate_family_search

  belongs_to  :person

  # has_many    :benefit_sponsors

  # Collection of insured:  employees, consumers, residents

  # All current and former members of this group
  embeds_many :family_members, cascade_callbacks: true
  embeds_many :special_enrollment_periods, cascade_callbacks: true
  embeds_many :irs_groups, cascade_callbacks: true
  embeds_many :households, cascade_callbacks: true, :before_add => :reset_active_household
  embeds_many :broker_agency_accounts
  embeds_many :general_agency_accounts
  embeds_many :documents, as: :documentable

  accepts_nested_attributes_for :special_enrollment_periods, :family_members, :irs_groups, :households, :broker_agency_accounts, :general_agency_accounts

  index({person_id: 1})
  index({e_case_id: 1}, { sparse: true })
  index({is_active: 1})
  index({submitted_at: 1})

  # child model indexes
  index({"family_members._id" => 1})
  index({"family_members.person_id" => 1})
  index({"family_members.broker_role_id" => 1})
  index({"family_members.is_primary_applicant" => 1})
  index({"family_members.hbx_enrollment_exemption.certificate_number" => 1})

  index({"households.hbx_enrollments.broker_agency_profile_id" => 1}, {sparse: true})
  index({"households.hbx_enrollments.effective_on" => 1})
  index({"households.hbx_enrollments.benefit_group_assignment_id" => 1})
  index({"households.hbx_enrollments.benefit_group_id" => 1})

  index({"households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.created_at" => 1},
         {name: "state_and_created"})

  index({"households.hbx_enrollments.plan_id" => 1}, { sparse: true })
  index({"households.hbx_enrollments.writing_agent_id" => 1}, { sparse: true })
  index({"households.hbx_enrollments.hbx_id" => 1})
  index({"households.hbx_enrollments.kind" => 1})
  index({"households.hbx_enrollments.submitted_at" => 1})
  index({"households.hbx_enrollments.effective_on" => 1})
  index({"households.hbx_enrollments.terminated_on" => 1}, { sparse: true })
  index({"households.hbx_enrollments.applied_aptc_amount" => 1})

  index({"households.tax_households.hbx_assigned_id" => 1})
  index({"households.tax_households.effective_starting_on" => 1})
  index({"households.tax_households.effective_ending_on" => 1})
  index({"households.tax_households.tax_household_member.financial_statement.submitted_date" => 1})

  index({"households.tax_households.eligibility_determinations._id" => 1})
  index({"households.tax_households.eligibility_determinations.e_pdc_id" => 1})
  index({"households.tax_households.eligibility_determinations.determined_on" => 1})
  index({"households.tax_households.eligibility_determinations.determined_at" => 1})
  index({"households.tax_households.eligibility_determinations.max_aptc.cents" => 1})

  index({"irs_groups.hbx_assigned_id" => 1})

  # index("households.tax_households_id")

  validates :renewal_consent_through_year,
            numericality: {only_integer: true, inclusion: 2014..2025},
            :allow_nil => true

  validates :e_case_id, uniqueness: true, allow_nil: true
  validate :family_integrity

  after_initialize :build_household
 # after_save :update_family_search_collection
 # after_destroy :remove_family_search_record

  scope :with_enrollment_hbx_id, ->(enrollment_hbx_id) {
      where("households.hbx_enrollments.hbx_id" => enrollment_hbx_id)
    }

  scope :all_with_single_family_member,       ->{ exists({:'family_members.1' => false}) }
  scope :all_with_multiple_family_members,    ->{ exists({:'family_members.1' => true})  }

  scope :all_current_households,              ->{ exists(households: true).order_by(:start_on.desc).limit(1).only(:_id, :"households._id") }
  scope :all_tax_households,                  ->{ exists(:"households.tax_households" => true) }
  scope :by_writing_agent_id,                 ->(broker_id){ where(broker_agency_accounts: {:$elemMatch=> {writing_agent_id: broker_id, is_active: true}})}
  scope :by_broker_agency_profile_id,         -> (broker_agency_profile_id) { where(broker_agency_accounts: {:$elemMatch=> {broker_agency_profile_id: broker_agency_profile_id, is_active: true}})}
  scope :by_general_agency_profile_id,         -> (general_agency_profile_id) { where(general_agency_accounts: {:$elemMatch=> {general_agency_profile_id: general_agency_profile_id, aasm_state: "active"}})}
  scope :all_assistance_applying,       ->{ unscoped.exists(:"households.tax_households.eligibility_determinations" => true).order(
                                                   :"households.tax_households.eligibility_determinations.determined_at".desc) }

  scope :all_assistance_receiving,      ->{ unscoped.where(:"households.tax_households.eligibility_determinations.max_aptc.cents".gt => 0).order(
                                                  :"households.tax_households.eligibility_determinations.determined_at".desc) }
  scope :active_assistance_receiving,   ->{ all_assistance_receiving.exists(:"households.tax_households.effective_ending_on" => false) }
  scope :all_plan_shopping,             ->{ exists(:"households.hbx_enrollments" => true) }


  scope :by_eligibility_determination_date_range, ->(start_at, end_at){ where(
                                                        :"households.tax_households.eligibility_determinations.determined_on".gte => start_at).and(
                                                        :"households.tax_households.eligibility_determinations.determined_on".lte => end_at
                                                      )
                                                    }

  scope :by_datetime_range,             ->(start_at, end_at){ where(:created_at.gte => start_at).and(:created_at.lte => end_at) }

  scope :all_enrollments,                     ->{  where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::ENROLLED_STATUSES) }
  scope :all_enrollments_by_writing_agent_id, ->(broker_id){ where(:"households.hbx_enrollments.writing_agent_id" => broker_id) }
  scope :all_enrollments_by_benefit_group_id, ->(benefit_group_id){where(:"households.hbx_enrollments.benefit_group_id" => benefit_group_id) }
  scope :by_enrollment_individual_market,     ->{ where(:"households.hbx_enrollments.kind".ne => "employer_sponsored") }
  scope :by_enrollment_shop_market,           ->{ where(:"households.hbx_enrollments.kind" => "employer_sponsored") }
  scope :by_enrollment_renewing,              ->{ where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::RENEWAL_STATUSES) }
  scope :by_enrollment_created_datetime_range,  ->(start_at, end_at){ where(:"households.hbx_enrollments.created_at" => { "$gte" => start_at, "$lte" => end_at} )}
  scope :by_enrollment_updated_datetime_range,  ->(start_at, end_at){ where(:"households.hbx_enrollments.updated_at" => { "$gte" => start_at, "$lte" => end_at} )}
  scope :by_enrollment_effective_date_range,    ->(start_on, end_on){ where(:"households.hbx_enrollments.effective_on" => { "$gte" => start_on, "$lte" => end_on} )}

  def update_family_search_collection
#    ViewFunctions::Family.run_after_save_search_update(self.id)
  end

  def coverage_waived?
    latest_household.hbx_enrollments.any? and latest_household.hbx_enrollments.waived.any?
  end

  def remove_family_search_record
    Searches::FamilySearch.where("id" => self.id).delete_all
  end

  def latest_household
    return households.first if households.size == 1
    households.order_by(:'submitted_at'.desc).limit(1).only(:households).first
    # persisted_household = households.select(&:persisted?) - [nil] #remove any nils
    # persisted_household.sort_by(&:submitted_at).last
  end

  def active_household
    # households.detect { |household| household.is_active? }
    latest_household
  end

  def enrolled_benefits
    # latest_household.try(:enrolled_hbx_enrollments)
  end

  def terminated_benefits
  end

  def renewal_benefits
  end

  def enrollments
    return [] if  latest_household.blank?
    latest_household.hbx_enrollments.show_enrollments

  end

  def primary_family_member
    family_members.detect { |family_member| family_member.is_primary_applicant? && family_member.is_active? }
  end

  def primary_applicant
    primary_family_member
  end

  def consent_applicant
    family_members.detect { |family_member| family_member.is_consent_applicant? && family_member.is_active? }
  end

  def active_family_members
    family_members.find_all { |family_member| family_member.is_active? }
  end

  def find_family_member_by_person(person)
    family_members.detect { |family_member| family_member.person_id.to_s == person._id.to_s }
  end

  def is_eligible_to_enroll?
    current_enrollment_eligibility_reasons.length > 0
  end

  def current_enrollment_eligibility_reasons
    current_special_enrollment_periods.collect do |sep|
      EnrollmentEligibilityReason.new(sep)
    end + current_eligible_open_enrollments
  end

  def is_under_open_enrollment?
    current_eligible_open_enrollments.length > 0
  end

  def is_under_ivl_open_enrollment?
    current_ivl_eligible_open_enrollments.length > 0
  end

  def is_under_shop_open_enrollment?
    current_shop_eligible_open_enrollments.length > 0
  end

  def current_eligible_open_enrollments
    current_shop_eligible_open_enrollments + current_ivl_eligible_open_enrollments
  end

  def current_ivl_eligible_open_enrollments
    eligible_open_enrollments = []

    benefit_sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
    (benefit_sponsorship.try(:benefit_coverage_periods) || []).each do |benefit_coverage_period|
      if benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
        eligible_open_enrollments << EnrollmentEligibilityReason.new(benefit_sponsorship)
      end
    end

    eligible_open_enrollments
  end

  def current_shop_eligible_open_enrollments
    eligible_open_enrollments = []

    if employee_roles = primary_applicant.try(:person).try(:employee_roles) # TODO only active employee roles
      employee_roles.each do |employee_role|
        if (benefit_group = employee_role.try(:benefit_group)) &&
          (employer_profile = employee_role.try(:employer_profile))
          employer_profile.try(:published_plan_year).try(:enrolling?) &&
          benefit_group.effective_on_for(employee_role.hired_on) > benefit_group.start_on

          eligible_open_enrollments << EnrollmentEligibilityReason.new(employer_profile)
        end
      end
    end

    eligible_open_enrollments

    # original implementation - to be removed after testing is proved to work - 2015-09-03
    # return [] unless primary_applicant
    # pri_person = primary_applicant.person
    # return [] unless pri_person
    # employee_role = pri_person.employee_roles.first
    # return [] unless employee_role
    # employer_profile = employee_role.employer_profile
    # return [] unless employer_profile
    # benefit_group = employee_role.benefit_group
    # return [] unless benefit_group
    # return [] if benefit_group.effective_on_for(employee_role.hired_on) > benefit_group.start_on
    # return [] unless employer_profile.published_plan_year.enrolling?
    # [EnrollmentEligibilityReason.new(employer_profile)]
  end

  # Life events trigger special enrollment periods
  def is_under_special_enrollment_period?
    return false if special_enrollment_periods.size == 0
    sep = special_enrollment_periods.order_by(:start_on.desc).limit(1).only(:special_enrollment_periods).first
    sep.is_active?
  end

  def current_special_enrollment_periods
    return [] if special_enrollment_periods.size == 0
    seps = special_enrollment_periods.order_by(:start_on.desc).only(:special_enrollment_periods)
    seps.reduce([]) { |list, event| list << event if event.is_active?; list }
  end

  def earliest_effective_sep
    special_enrollment_periods.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  def earliest_effective_shop_sep
    special_enrollment_periods.shop_market.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  def earliest_effective_ivl_sep
    special_enrollment_periods.individual_market.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  def latest_shop_sep
    special_enrollment_periods.shop_market.order_by(:submitted_at.desc).to_a.detect{ |sep| sep.is_active? }
  end

  def terminate_date_for_shop_by_enrollment(enrollment=nil)
    if latest_shop_sep.present?
      terminate_date = if latest_shop_sep.qualifying_life_event_kind.reason == 'death'
                         latest_shop_sep.qle_on
                       else
                         latest_shop_sep.qle_on.end_of_month
                       end
      if enrollment.present?
        if enrollment.effective_on > latest_shop_sep.qle_on
          terminate_date = enrollment.effective_on
        elsif enrollment.effective_on >= terminate_date
          terminate_date = TimeKeeper.date_of_record.end_of_month
        end
      end
      terminate_date
    else
      TimeKeeper.date_of_record.end_of_month
    end
  end

  # List of SEPs active for this Application Group today, or passed date
  def active_seps
    special_enrollment_periods.find_all { |sep| sep.is_active? }
  end

  # single SEP with latest end date from list of active SEPs
  def current_sep
    active_seps.max { |sep| sep.end_on }
  end

  def active_broker_roles
    active_household.hbx_enrollments.reduce([]) { |b, e| b << e.broker_role if e.is_active? && !e.broker_role.blank? } || []
  end

  def build_from_employee_role(employee_role)
    build_from_person(employee_role.person)
  end

  def build_from_person(person)
    add_family_member(person, is_primary_applicant: true)
    person.person_relationships.each { |kin| add_family_member(kin.relative) }
    self
  end

  def relate_new_member(person, relationship)
    primary_applicant_person.ensure_relationship_with(person, relationship)
    add_family_member(person)
  end

  def add_family_member(person, **opts)
#    raise ArgumentError.new("expected Person") unless person.is_a? Person

    is_primary_applicant     = opts[:is_primary_applicant]  || false
    is_coverage_applicant    = opts[:is_coverage_applicant] || true
    is_consent_applicant     = opts[:is_consent_applicant]  || false

    existing_family_member = family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }

    if existing_family_member
      active_household.add_household_coverage_member(existing_family_member)
      existing_family_member.is_active = true
      return existing_family_member
    end

    family_member = family_members.build(
        person: person,
        is_primary_applicant: is_primary_applicant,
        is_coverage_applicant: is_coverage_applicant,
        is_consent_applicant: is_consent_applicant
      )

    active_household.add_household_coverage_member(family_member)
    family_member
  end

  def remove_family_member(person)
    family_member = find_family_member_by_person(person)
    if family_member.present?
      family_member.is_active = false
      active_household.remove_family_member(family_member)
    end

    family_member
  end

  def person_is_family_member?(person)
    find_family_member_by_person(person).present?
  end

  def dependents
    family_members.reject(&:is_primary_applicant)
  end

  def people_relationship_map
    map = Hash.new
    people.each do |person|
      map[person] = person_relationships.detect { |r| r.object_person == person.id }.relationship_kind
    end
    map
  end

  def is_active?
    self.is_active
  end

  def find_matching_inactive_member(personish)
    inactive_members = family_members.reject(&:is_active)
    return nil if inactive_members.blank?
    if !personish.ssn.blank?
      inactive_members.detect { |mem| mem.person.ssn == personish.ssn }
    else
      return nil if personish.dob.blank?
      search_dob = personish.dob.strftime("%m/%d/%Y")
      inactive_members.detect do |mem|
        mp = mem.person
        mem_dob = mem.dob.blank? ? nil : mem.dob.strftime("%m/%d/%Y")
        (personish.last_name.downcase.strip == mp.last_name.downcase.strip) &&
          (personish.first_name.downcase.strip == mp.first_name.downcase.strip) &&
          (search_dob == mem_dob)
      end
    end
  end

  def hire_broker_agency(broker_role_id)
    return unless broker_role_id
    existing_agency = current_broker_agency
    broker_agency_profile_id = BrokerRole.find(broker_role_id).try(:broker_agency_profile_id)
    fire_broker_agency(existing_agency) if existing_agency
    start_on = Time.now
    broker_agency_account = BrokerAgencyAccount.new(broker_agency_profile_id: broker_agency_profile_id, writing_agent_id: broker_role_id, start_on: start_on, is_active: true)
    broker_agency_accounts.push(broker_agency_account)
    self.save
  end

  def fire_broker_agency(existing_agency)
    existing_agency.update_attributes!(end_on: (TimeKeeper.date_of_record.to_date - 1.day).end_of_day, is_active: false)
  end

  def current_broker_agency
    broker_agency_accounts.detect { |account| account.is_active? }
  end

  def ivl_unverified_enrollments
    return [] if enrollments.empty?
    enrollments.individual_market.verification_needed
  end

  class << self
    # Manage: SEPs, FamilyMemberAgeOff
    def advance_day(new_date)
    end

    def default_search_order
      [
          ["primary_applicant.name_last", 1],
          ["primary_applicant.name_first", 1]
      ]
    end

    def find_or_build_from_employee_role(new_employee_role)
      existing_family = Family.find_by_employee_role(new_employee_role)

      if existing_family.present?
        existing_family
      else
        family = Family.new
        family.build_from_employee_role(new_employee_role)

        family.save!
        family
      end
    end

    # TODO: should probably go away assuming 1 person should only have 1 family with them as primary
    def find_all_by_primary_applicant(person)
      Family.find_all_by_person(person).select() { |f| f.primary_applicant.person.id.to_s == person.id.to_s }
    end

    def find_by_primary_family_member(person)
      find_all_by_primary_applicant(person).first
    end

    def find_by_employee_role(employee_role)
      find_all_by_primary_applicant(employee_role.person).first
    end

    def find_by_primary_applicant(person)
      find_all_by_primary_applicant(person).first
    end

    def find_all_by_person(person)
      Family.where("family_members.person_id" => person.id)
    end

    def find_family_member(family_member_id)
      return [] if family_member_id.nil?
      family = Family.where("family_members._id" => BSON::ObjectId.from_string(family_member_id)).first
      family.family_members.detect { |member| member._id.to_s == family_member_id.to_s }
    end

    def find_by_case_id(case_id)
      where({"e_case_id" => case_id}).first
    end
  end

  def clear_blank_fields
    if e_case_id.blank?
      unset("e_case_id")
    end
  end

  def build_consumer_role(family_member, opts = {})
    person = family_member.person
    return if person.consumer_role.present?
    person.build_consumer_role({:is_applicant => false}.merge(opts))
    person.save!
  end

  def check_for_consumer_role
    if primary_applicant.person.consumer_role.present?
      active_family_members.each do |family_member|
        build_consumer_role(family_member)
      end
    end
  end

  def enrolled_hbx_enrollments
    latest_household.try(:enrolled_hbx_enrollments)
  end

  def enrolled_including_waived_hbx_enrollments
    latest_household.try(:enrolled_including_waived_hbx_enrollments)
  end

  def save_relevant_coverage_households
    households.each do |household|
      household.coverage_households.each{|hh| hh.save }
    end
  end

  def has_aptc_hbx_enrollment?
    enrollments = latest_household.hbx_enrollments.active rescue []
    enrollments.any? {|enrollment| enrollment.applied_aptc_amount > 0}
  end

  def update_aptc_block_status
    #max_aptc = latest_household.latest_active_tax_household.latest_eligibility_determination.max_aptc rescue 0
    eligibility_determinations = latest_household.latest_active_tax_household.eligibility_determinations rescue nil

    if eligibility_determinations.present? && has_aptc_hbx_enrollment?
      self.set(status: "aptc_block")
    end
  end

  def aptc_blocked?
    status == "aptc_block"
  end

  def is_blocked_by_qle_and_assistance?(qle=nil, assistance=nil)
    return false if qle.present?
    return false if assistance.blank? #or qle.blank?
    return false if status == "aptc_unblock"
    return true if status == "aptc_block"

    #max_aptc = latest_household.latest_active_tax_household.latest_eligibility_determination.max_aptc rescue 0
    #if max_aptc > 0 && qle.individual? && qle.family_structure_changed?
    #  true
    #else
    #  false
    #end
  end

  def self.by_special_enrollment_period_id(special_enrollment_period_id)
    Family.where("special_enrollment_periods._id" => special_enrollment_period_id)
  end

  def all_enrollments
    if self.active_household.present?
      active_household.hbx_enrollments
    end
  end

  def enrollments_for_display
    Family.collection.aggregate([
      {"$match" => {'_id' => self._id}},
      {"$unwind" => '$households'},
      {"$unwind" => '$households.hbx_enrollments'},
      {"$match" => {"households.hbx_enrollments.aasm_state" => {"$ne" => 'inactive'} }},
      {"$match" => {"households.hbx_enrollments.aasm_state" => {"$ne" => 'void'} }},
      {"$match" => {"households.hbx_enrollments.external_enrollment" => {"$ne" => true}}},
      {"$match" => {"households.hbx_enrollments.aasm_state" => {"$ne" => "coverage_canceled"}}},
      {"$sort" => {"households.hbx_enrollments.submitted_at" => -1 }},
      {"$group" => {'_id' => {
                  'year' => { "$year" => '$households.hbx_enrollments.effective_on'},
                  'month' => { "$month" => '$households.hbx_enrollments.effective_on'},
                  'day' => { "$dayOfMonth" => '$households.hbx_enrollments.effective_on'},
                  'subscriber_id' => '$households.hbx_enrollments.enrollment_signature',
                  'provider_id'   => '$households.hbx_enrollments.carrier_profile_id',
                  'state' => '$households.hbx_enrollments.aasm_state',
                  'market' => '$households.hbx_enrollments.kind',
                  'coverage_kind' => '$households.hbx_enrollments.coverage_kind'},
                  "hbx_enrollment" => { "$first" => '$households.hbx_enrollments'}}},
      {"$project" => {'hbx_enrollment._id' => 1, '_id' => 1}}
      ],
      :allow_disk_use => true)
  end

  def waivers_for_display
    Family.collection.aggregate([
      {"$match" => {'_id' => self._id}},
      {"$unwind" => '$households'},
      {"$unwind" => '$households.hbx_enrollments'},
      {"$match" => {'households.hbx_enrollments.aasm_state' => 'inactive'}},
      {"$sort" => {"households.hbx_enrollments.submitted_at" => -1 }},
      {"$group" => {'_id' => {'year' => { "$year" => '$households.hbx_enrollments.effective_on'},
                    'state' => '$households.hbx_enrollments.aasm_state',
                    'kind' => '$households.hbx_enrollments.kind',
                    'coverage_kind' => '$households.hbx_enrollments.coverage_kind'}, "hbx_enrollment" => { "$first" => '$households.hbx_enrollments'}}},
      {"$project" => {'hbx_enrollment._id' => 1, '_id' => 0}}
      ],
      :allow_disk_use => true)
  end

  def generate_family_search
    ::MapReduce::FamilySearchForFamily.populate_for(self)
  end
private
  def build_household
    if households.size == 0
      irs_group = initialize_irs_group
      initialize_household(irs_group)
    end
  end

  def family_integrity
    only_one_active_primary_family
    single_primary_family_member
    all_family_member_relations_defined
    single_active_household
    no_duplicate_family_members
  end

  def primary_applicant_person
    return nil unless primary_applicant.present?
    primary_applicant.person
  end

  def only_one_active_primary_family
    return unless primary_family_member.present? && primary_family_member.person.present?
    families_with_same_primary = Family.where(
      "family_members" => {
        "$elemMatch" => {
          "is_primary_applicant" => true,
          "person_id" => BSON::ObjectId.from_string(primary_family_member.person_id.to_s)
        }
      },
      "is_active" => true
    )
    if (families_with_same_primary.any? { |fam| fam.id.to_s != self.id.to_s })
      self.errors.add(:base, "has another active family with the same primary applicant")
    end
  end

  def single_primary_family_member
    list = family_members.reduce([]) { |list, family_member| list << family_member if family_member.is_primary_applicant?; list }
    self.errors.add(:family_members, "one family member must be primary family member") if list.size == 0
    self.errors.add(:family_members, "may not have more than one primary family member") if list.size > 1
  end

  def all_family_member_relations_defined
    return unless primary_family_member.present? && primary_family_member.person.present?
    primary_member_id = primary_family_member.id
    primary_person = primary_family_member.person
    other_family_members = family_members.select { |fm| (fm.id.to_s != primary_member_id.to_s) && fm.person.present? }
    undefined_relations = other_family_members.any? { |fm| primary_person.find_relationship_with(fm.person).blank? }
    errors.add(:family_members, "relationships between primary_family_member and all family_members must be defined") if undefined_relations
  end

  def single_active_household
    list = households.reduce([]) { |list, household| list << household if household.is_active?; list }
    self.errors.add(:households, "one household must be active") if list.size == 0
    self.errors.add(:households, "may not have more than one active household") if list.size > 1
  end

  def initialize_irs_group
    irs_groups.build(effective_starting_on: TimeKeeper.date_of_record)
  end

  def initialize_household(irs_group)
    households.build(irs_group: irs_group, effective_starting_on: irs_group.effective_starting_on, submitted_at: DateTime.current)
  end

  def no_duplicate_family_members
    family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:family_members, "Duplicate family_members for person: #{k}\n" +
                          "family_members: #{v.inspect}")
    end
  end

  # This method will return true only if all the family_members in tax_household_members and coverage_household_members are present in self.family_members
  def integrity_of_family_member_objects
    return true if self.households.blank?

    family_members_in_family = self.family_members - [nil]
    tax_household_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:tax_households).flat_map(&:tax_household_members).map(&:applicant_id))
    coverage_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:coverage_households).flat_map(&:coverage_household_members).map(&:applicant_id))
    tax_household_family_members_valid && coverage_family_members_valid
  end

  def are_arrays_of_family_members_same?(base_set, test_set)
    base_set.uniq.sort == test_set.uniq.sort
  end

  def reset_active_household(new_household)
    households.each do |household|
      household.is_active = false
    end
    new_household.is_active = true
  end

  def valid_relationship?(family_member)
    return true if primary_applicant.nil? #responsible party case
    return true if primary_applicant.person.id == family_member.person.id

    if ImmediateFamily.include? primary_applicant.person.find_relationship_with(family_member.person)
      return true
    else
      return false
    end
  end
end
