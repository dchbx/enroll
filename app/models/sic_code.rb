class SicCode
  include Mongoid::Document
  extend SicConcern

  field :division_code, type: String
  field :division_label, type: String
  field :major_group_code, type: String
  field :major_group_label, type: String
  field :industry_group_code, type: String
  field :industry_group_label, type: String
  field :sic_code, type: String
  field :sic_label, type: String

  validates_presence_of :division_code, :division_label, :major_group_code, :major_group_label, :industry_group_code, :industry_group_label, :sic_code, :sic_label
end