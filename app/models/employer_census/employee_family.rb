class EmployerCensus::EmployeeFamily

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile

  field :plan_year_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

  # UserID that connected and timestamp
  field :linked_employee_role_id, type: BSON::ObjectId
  field :linked_at, type: DateTime

  field :terminated, type: Boolean, default: false

  embeds_one :census_employee,
    class_name: "EmployerCensus::Employee",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_employee, reject_if: :all_blank, allow_destroy: true

  embeds_many :census_dependents,
    class_name: "EmployerCensus::Dependent",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_dependents, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :census_employee

  scope :active,  ->{ where(:terminated => false) }
  scope :terminated,      ->{ where(:terminated => true) }

  scope :linked,     ->{ where(:is_linked => true) }
  scope :unlinked,   ->{ where(:is_linked => false) }

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    new_family = self.dup
    new_family.delink_employee_role
    new_family.terminated = false

    if self.census_employee.present?
      new_family.census_employee = self.census_employee
      new_family.census_employee.hired_on = nil
      new_family.census_employee.terminated_on = nil
    end

    new_family.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_family
  end

  def parent
    raise "undefined parent EmployerProfile" unless employer_profile?
    self.employer_profile
  end

  def plan_year=(new_plan_year)
    self.plan_year_id = new_plan_year._id unless new_plan_year.blank?
  end

  def plan_year
    return if plan_year.blank?
    parent.plan_years.find(self.plan_year_id)
  end

  def benefit_group=(new_benefit_group)
    self.benefit_group_id = new_benefit_group._id unless new_benefit_group.blank?
    self.plan_year = new_benefit_group.plan_year
  end

  def benefit_group
    parent.plan_year.benefit_group.find(:plan_year_id => self.benefit_group_id)
  end

  def link_employee_role(new_employee_role)
    #
    if is_linked?
      raise EmployeeFamilyLinkError.new(
          new_employee_role,
          message: "census_employee_family is already linked to employee_role"
        )
    end

    # Only one instance of the same employee may be linkable
    if parent.employee_families.where("census_employee.ssn" => new_employee_role.ssn,
                                      "linked_employee_role_id" => nil,
                                      "terminated" => false).size > 1
    # if parent.employee_families.where(census_employee.ssn == new_employee_role.ssn && census_employee.is_linkable?).size > 1
      raise EmployeeFamilyLinkError.new(
          new_employee_role,
          message: "more than one active census_employee_family instance with this employee"
        )
    end

    self.linked_employee_role_id = new_employee_role._id
    self.linked_at = Time.now
    self
  end

  def linked_employee_role
    EmployeeRole.find(self.linked_employee_role_id) if is_linked?
  end

  def delink_employee_role
    self.linked_employee_role_id = nil
    self.linked_at = nil
    self
  end

  def is_linked?
    self.linked_employee_role_id.present?
  end

  def is_linkable?
    (is_linked? == false) && (is_terminated? == false)
  end

  def terminate(last_day_of_work)
    self.census_employee.terminated_on = date
    self.terminated = true
    self
  end

  def is_terminated?
    self.terminated
  end

end

class EmployeeFamilyLinkError < StandardError
  def initialize(employee, options={})
    @employee = employee
    @message = options[:message]
    super("#{message} - #{employee.inspect}")
  end
end
