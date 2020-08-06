# frozen_string_literal: true

class NoticeTriggerElementGroup
  include Mongoid::Document

  embedded_in :notice_trigger

  RECIPIENT_KINDS = %w[employer employee consumer former_employee employee_dependents broker hbx_admin hbx_staff csr case_worker].freeze
  DELIVERY_METHOD_KINDS = %w[secure_message email paper].freeze
  MARKET_PLACE_KINDS = %w[individual shop].freeze


  field :market_places,                       type: Array, default: ["any"]
  field :primary_recipients,                  type: Array, default: ["any"]
  field :primary_recipient_delivery_method,   type: Array, default: ["paper"]
  field :secondary_recipients,                type: Array, default: ["any"]
  field :secondary_recipient_delivery_method, type: Array, default: ["paper"]


  def notice_peferences
    {
      :recipients => primary_recipients.join(','),
      :delivery_method => primary_recipient_delivery_method.join(',')
    }
  end

end
