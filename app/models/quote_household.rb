class QuoteHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies

  embedded_in :quote
  embeds_many :quote_members


  field :family_id, type: String

  # Quote Benefit Group ID for this employee on the roster
  field :quote_benefit_group_id, type: BSON::ObjectId
  field :is_cobra_status?, type: Boolean, default: false
  validates_uniqueness_of :family_id
  validate :one_employee_per_family, :one_spouse_or_domestic_partner_per_family

  before_save :assign_benefit_group_id

  accepts_nested_attributes_for :quote_members

  def employee?
    quote_members.where("employee_relationship" => "employee").count == 1 ? true : false
  end

  def spouse?
    quote_members.where("employee_relationship" => "spouse").count == 1 ? true : false
  end

  def children?
    quote_members.where("employee_relationship" => "child_under_26").count >= 1 ? true : false
  end

  def employee
    quote_members.where("employee_relationship" => "employee").first
  end

  def dependents
    quote_members.ne("employee_relationship" => "employee")
  end

  def quote_benefit_group
    quote.quote_benefit_groups.find(self.quote_benefit_group_id)
  end

  def assign_benefit_group_id
    if quote_benefit_group_id.nil?
      self.quote_benefit_group_id = quote.quote_benefit_groups.first.id
    end
  end

  private

  def one_spouse_or_domestic_partner_per_family
    if quote_members.where(:employee_relationship => { "$in" => ["spouse" , "domestic_partner"]}).count > 1
      errors.add(:"quote_members.employee_relationship","Should be unique")
    end
  end

  def one_employee_per_family
    if quote_members.where("employee_relationship" => "employee").count > 1
      errors.add(:"quote_members.employee_relationship","There should be only one employee per family.")
    end
  end

end
