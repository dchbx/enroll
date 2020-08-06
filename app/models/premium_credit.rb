# frozen_string_literal: true

class PremiumCredit
  include Mongoid::Document
  include Mongoid::Timestamps

  # Second Lowest Cost Silver Plan
  field :slcsp_id, type: BSON::ObjectId

  field :aptc_in_cents, type: Integer, default: 0
  field :start_on, type: Date
  field :end_on, type: Date

  field :is_voided, type: Boolean, default: false
  field :is_corrected, type: Boolean, default: false

  def slcsp=(new_slcsp)
    raise ArgumentError, "expected Plan class" unless new_slcsp.is_a? Plan
    self.new_slcsp_id = new_slcsp._id
    @slcsp = new_slcsp
  end

  def slcsp
    return @slcsp if defined? @slcsp
    @slcsp = Plan.find(self.new_slcsp_id) unless new_slcsp_id.blank?
  end

  def is_voided?
    is_voided
  end

  def is_corrected?
    is_corrected
  end

end
