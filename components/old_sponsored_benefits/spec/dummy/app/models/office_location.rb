class OfficeLocation
  include Mongoid::Document

  embedded_in :organization
  field :is_primary, type: Boolean, default: true

  embeds_one :address, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  embeds_one :phone, cascade_callbacks: true, validate: true
  accepts_nested_attributes_for :phone, reject_if: :all_blank, allow_destroy: true
end