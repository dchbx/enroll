# frozen_string_literal: true

# rubocop:disable Naming/ConstantName

class HbxProfile

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization

  field :cms_id, type: String
  field :us_state_abbreviation, type: String

  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :entity_kind, :entity_kind=, to: :organization, allow_nil: true

  embeds_many :hbx_staff_roles
  embeds_many :enrollment_periods # TODO: deprecated - should be removed by 2015-09-03 - Sean Carley

  embeds_one :benefit_sponsorship, cascade_callbacks: true
  embeds_one :inbox, as: :recipient, cascade_callbacks: true

  accepts_nested_attributes_for :inbox, :benefit_sponsorship

  validates_presence_of :us_state_abbreviation, :cms_id

  after_initialize :build_nested_models

  def advance_day; end

  def advance_month; end

  def advance_quarter; end

  def advance_year; end

  def under_open_enrollment?
    benefit_sponsorship.present? && benefit_sponsorship.is_under_open_enrollment? ? true : false
  end

  def active_employers
    EmployerProfile.active
  end

  def inactive_employers
    EmployerProfile.inactive
  end

  def active_employees
    CensusEmployee.active
  end

  def active_broker_agencies
    BrokerAgencyProfile.active
  end

  def inactive_broker_agencies
    BrokerAgencyProfile.inactive
  end

  def active_brokers
    BrokerRole.active
  end

  def inactive_brokers
    BrokerRole.inactive
  end


  class << self
    def find(id)
      org = Organization.where("hbx_profile._id" => BSON::ObjectId.from_string(id)).first
      org.hbx_profile if org.present?
    end

    def find_by_cms_id(id)
      org = Organization.where("hbx_profile.cms_id": id).first
      org.hbx_profile if org.present?
    end

    def find_by_state_abbreviation(state)
      org = Organization.where("hbx_profile.us_state_abbreviation": state.to_s.upcase).first
      org.hbx_profile if org.present?
    end

    def all
      Organization.exists(hbx_profile: true).all.reduce([]) { |set, org| set << org.hbx_profile }
    end

    def current_hbx
      find_by_state_abbreviation("DC")
    end

    def faa_application_applicable_year
      calender_year = TimeKeeper.date_of_record.year
      enrollment_start_on_year = Settings.aca.individual_market.open_enrollment.start_on.to_date

      if current_hbx&.under_open_enrollment? && calender_year == enrollment_start_on_year.year
        calender_year + 1
      else
        calender_year
      end
    end

    def transmit_group_xml(employer_profile_ids)
      hbx_ids = []
      employer_profile_ids.each do |empr_id|
        empr = EmployerProfile.find(empr_id)
        hbx_ids << empr.hbx_id
        empr.update_attribute(:xml_transmitted_timestamp, Time.now.utc)
      end
      notify("acapi.info.events.employer.group_files_requested", { body: hbx_ids })
    end

    def search_random(search_param)
      if search_param.present?
        organizations = Organization.where(legal_name: /#{search_param}/i)
        broker_agency_profiles = []
        organizations.each do |org|
          broker_agency_profiles << org.broker_agency_profile if org.broker_agency_profile.present?
        end
      else
        broker_agency_profiles = BrokerAgencyProfile.all
      end
      broker_agency_profiles
    end
  end

  StateName = "District of Columbia"
  StateAbbreviation = "DC"
  CallCenterName = "DC Health Link's Customer Care Center"
  CallCenterPhoneNumber = "1-855-532-5465"
  ShortName = "DC Health Link"

  IndividualEnrollmentDueDayOfMonth = Settings.aca.individual_market.monthly_enrollment_due_on


  ShopOpenEnrollmentBeginDueDayOfMonth = Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days
  ShopPlanYearPublishedDueDayOfMonth = ShopOpenEnrollmentBeginDueDayOfMonth

  private

  def build_nested_models
    # build_inbox if inbox.nil?
  end

  def save_inbox
    welcome_subject = "Welcome to #{Settings.site.short_name}"
    welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end
end

# rubocop:enable Naming/ConstantName

