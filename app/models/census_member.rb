class CensusMember
  include Mongoid::Document
  include Mongoid::Timestamps
  include UnsetableSparseFields
  include SponsoredBenefits::Concerns::Ssn
  include SponsoredBenefits::Concerns::Dob

  validates_with Validations::DateRangeValidator

  GENDER_KINDS = %W(male female)

  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String

  field :encrypted_ssn, type: String
  field :gender, type: String
  field :dob, type: Date

  include StrippedNames

  field :employee_relationship, type: String
  field :employer_assigned_family_id, type: String

  embeds_one :address
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  embeds_one :email
  accepts_nested_attributes_for :email, allow_destroy: true

  validates :gender,
  allow_blank: false,
  inclusion: { in: GENDER_KINDS, message: "must be selected" }


  validates_presence_of :first_name, :last_name, :employee_relationship, :dob

  def full_name
    [first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def date_of_birth=(val)
    self.dob = Date.strptime(val, "%Y-%m-%d").to_date rescue nil
  end

  def gender=(val)
    if val.blank?
      write_attribute(:gender, nil)
      return
    end
    write_attribute(:gender, val.downcase)
  end

  def relationship_string
    if is_a?(CensusEmployee)
      "employee"
    else
      relationship_mapping[employee_relationship]
    end
  end

  def relationship_mapping
    {
      "self" => "employee",
      "spouse" => "spouse",
      "domestic_partner" => "domestic partner",
      "child_under_26" => "child",
      "disabled_child_26_and_over" => "disabled child"
    }
  end

  def email_address
    return nil unless email.present?
    email.address
  end
end
