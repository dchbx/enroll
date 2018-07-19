class AssisterRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person
  field :organization, type: String

end
