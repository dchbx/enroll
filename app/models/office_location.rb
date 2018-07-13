class OfficeLocation
  include Mongoid::Document
  include Config::AcaModelConcern
  embedded_in :organization

  field :is_primary, type: Boolean, default: true

  embeds_one :address, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true
  embeds_one :phone, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :phone, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :address
  validates_presence_of :phone, if: :primary_or_branch?

  validate :address_includes_county_for_employers_primary_location

  alias_method :is_primary?, :is_primary

  def address_includes_county_for_employers_primary_location
    return unless is_an_employer? && OfficeLocation.validate_county?
    if address.kind == 'primary' && address.county.blank?
      self.errors.add(:base, 'Employers must have a valid County for their primary office location')
    end
  end

  def parent
    self.organization
  end

  def is_an_employer?
    return false if organization.nil?
    organization.employer_profile.present?
  end

  def primary_or_branch?
    ['primary', 'branch'].include? address.kind if address.present?
  end

  # TODO -- only one office location can be primary
  # def is_primary=(new_primary_value)
  #   if parent.present? && new_primary_value == true
  #     parent.office_locations.each { |loc| loc.is_primary == false unless loc == self }
  #   end
  # end

end
