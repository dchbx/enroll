class Setting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String, default: ""
  field :value, type: String, default: ""

  index({name: 1}, {unique: true})

  def self.get_individual_market_monthly_enrollment_due_on
    setting_record = Setting.where(name: "individual_market_monthly_enrollment_due_on").last
    setting_record = Setting.create(name: "individual_market_monthly_enrollment_due_on", value: '19') if setting_record.blank?

    setting_record
  end

  def self.individual_market_monthly_enrollment_due_on
    setting_record = get_individual_market_monthly_enrollment_due_on
    setting_record.value.to_i
  end
end
