class EmployeeRole
  include Mongoid::Document
  include Acapi::Notifiers
  include ModelEvents::EmployeeRole
  include ::BenefitSponsors::Concerns::Observable

  embedded_in :person

  field :employer_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_employer_profile_id, type: BSON::ObjectId
  field :census_employee_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId  # TODO: Deprecate
  field :employment_status, type: String
  field :hired_on, type: Date
  field :terminated_on, type: Date
  field :is_active, type: Boolean, default: true
  field :bookmark_url, type: String, default: nil
  field :contact_method, type: String, default: "Paper and Electronic communications"
  field :language_preference, type: String, default: "English"

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true
  delegate :primary_family, to: :person, allow_nil: true
#  delegate :hired_on, to: :census_employee, allow_nil: true
  delegate :benefit_package_for_date, to: :census_employee, allow_nil: true
  delegate :benefit_package_for_open_enrollment, to: :census_employee, allow_nil: true

  validates_presence_of :ssn, :dob, :gender, :hired_on
  # validates_presence_of :employer_profile_id
  # validates_presence_of :benefit_sponsors_employer_profile_id
  validates_presence_of :employer_profile_id, :if => Proc.new { |m| m.benefit_sponsors_employer_profile_id.blank? }
  validates_presence_of :benefit_sponsors_employer_profile_id, :if => Proc.new { |m| m.employer_profile_id.blank? }
  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }

  accepts_nested_attributes_for :person

  before_save :termination_date_must_follow_hire_date

  after_create :notify_on_create
  add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_employee_role_events]

  def self.find(employee_role_id)
    bson_id = BSON::ObjectId.from_string(employee_role_id)
    person = Person.where({"employee_roles._id" => bson_id })
    person.first.employee_roles.detect { |ee| ee.id == bson_id } unless person.size < 1
  end

  def is_case_old?
    self.benefit_sponsors_employer_profile_id.blank?
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.class.to_s.match(/EmployerProfile/)
    if new_employer_profile.kind_of?(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile)
      self.benefit_sponsors_employer_profile_id = new_employer_profile._id
    else
      self.employer_profile_id = new_employer_profile._id
    end
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    if is_case_old?
      @employer_profile = EmployerProfile.find(self.employer_profile_id)
    else
      @employer_profile =  BenefitSponsors::Organizations::Organization.employer_profiles.where(
        :"profiles._id" => BSON::ObjectId.from_string(benefit_sponsors_employer_profile_id)
      ).first.employer_profile
    end
  end

  def new_census_employee=(new_census_employee)
    raise ArgumentError.new("expected CensusEmployee class") unless new_census_employee.is_a? ::CensusEmployee
    self.census_employee_id = new_census_employee._id
    @census_employee = new_census_employee
  end

  def new_census_employee
    return @census_employee if defined? @census_employee
    @census_employee = ::CensusEmployee.find(self.census_employee_id) unless census_employee_id.blank?
  end

  alias_method :census_employee=, :new_census_employee=
  alias_method :census_employee, :new_census_employee

  def is_active?
    census_employee && census_employee.is_active?
  end

  def coverage_effective_on(current_benefit_group: nil, qle: false)
    if qle && benefit_package(qle: qle).present?
      current_benefit_group = benefit_package(qle: qle)
    end

    census_employee.coverage_effective_on(current_benefit_group)
  end

  def benefit_group(qle: false)
    warn "[Deprecated] Instead use benefit_package(qle: true/false(default))"
    benefit_package(qle: qle)
  end

  def can_enroll_as_new_hire?
    census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record)
  end

private

  def termination_date_must_follow_hire_date
    return if hired_on.nil? || terminated_on.nil?
    errors.add(:terminated_on, "terminated_on cannot preceed hired_on") if terminated_on < hired_on
  end
end
