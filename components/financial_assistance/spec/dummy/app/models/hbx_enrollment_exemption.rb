# frozen_string_literal: true

class HbxEnrollmentExemption
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %w[hardship health_care_ministry_member incarceration indian_tribe_member religious_conscience].freeze

  embedded_in :family_member

  field :kind, type: String
  field :certificate_number, type: String
  field :start_date, type: Date
  field :end_date, type: Date

  field :applicant_id, type: BSON::ObjectId
  field :irs_group_id, type: BSON::ObjectId

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind,
            presence: true,
            allow_blank: false,
            allow_nil: false,
            inclusion: {in: KINDS}


  def parent
    raise "undefined parent ApplicationGroup" unless application_group?
    self.family
  end

  def irs_group=(irs_instance)
    return unless irs_instance.is_a? IrsGroup
    self.irs_group_id = irs_instance._id
    @irs_group = irs_instance
  end

  def irs_group
    return @irs_group if defined? @irs_group
    @irs_group = parent.irs_group.find(self.irs_group_id)
  end


end
