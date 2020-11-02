# frozen_string_literal: true

class IrsGroup
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :family

#  auto_increment :hbx_assigned_id, seed: 1_000_000_000_000_000 #The 16digit IrsGroup identifier as required by IRS

  field :hbx_assigned_id, type: String
  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :is_active, type: Boolean, default: true

  before_save :set_effective_starting_on
  before_save :set_effective_end_on

  def parent
    raise "undefined parent ApplicationGroup" unless family?
    self.family
  end

  # embedded association: has_many :tax_households
  def households
    parent.households.where(:irs_group_id => self.id)
  end

  def is_active?
    self.is_active
  end

  private

  def set_effective_starting_on
    self.effective_starting_on = family.active_household.effective_starting_on if family.active_household
  end

  def set_effective_end_on
    self.effective_ending_on = family.active_household.effective_ending_on if family.active_household
  end
end
