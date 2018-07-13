class Organization

  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_id, type: String
  field :issuer_assigned_id, type: String
  field :legal_name, type: String
  field :dba, type: String
  field :fein, type: String
  field :home_page, type: String

  embeds_one :employer_profile, cascade_callbacks: true, validate: true
      
end