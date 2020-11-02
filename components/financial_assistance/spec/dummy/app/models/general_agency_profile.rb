# frozen_string_literal: true

# rubocop:disable all

class GeneralAgencyProfile
  include Mongoid::Document
  include Mongoid::Timestamps


  # for market_kind
  MARKET_KINDS = %w[individual shop both].freeze
  MARKET_KINDS_OPTIONS = {
    "Individual & Family Marketplace ONLY" => "individual",
    "Small Business Marketplace ONLY" => "shop",
    "Both – Individual & Family AND Small Business Marketplaces" => "both"
  }.freeze


  field :entity_kind, type: String
  field :market_kind, type: String
  field :corporate_npn, type: String
  field :languages_spoken, type: Array, default: ["en"] # TODO
  field :working_hours, type: Boolean, default: false
  field :accept_new_clients, type: Boolean
  field :aasm_state, type: String, default: 'is_applicant'
  field :aasm_state_set_on, type: Date

  # for organizations
  embedded_in :organization
  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :home_page, :home_page=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

  has_many :general_agency_contacts, class_name: "Person", inverse_of: :general_agency_contact
  accepts_nested_attributes_for :general_agency_contacts, reject_if: :all_blank, allow_destroy: true


  # embeds_many :documents, as: :documentable
  embeds_one :inbox, as: :recipient, cascade_callbacks: true
  accepts_nested_attributes_for :inbox
  after_initialize :build_nested_models

  def market_kind=(new_market_kind)
    write_attribute(:market_kind, new_market_kind.to_s.downcase)
  end

  def general_agency_staff_roles
    Person.where("general_agency_staff_roles.general_agency_profile_id" => BSON::ObjectId.from_string(self.id)).map {|p| p.general_agency_staff_roles.detect {|s| s.general_agency_profile_id == id}}
  end

  def legal_name
    organization.legal_name
  end

  def phone
    office = organization.primary_office_location
    office && office.phone.to_s
  end

  def languages
    if languages_spoken.any?
      languages_spoken.map {|lan| LanguageList::LanguageInfo.find(lan).name if LanguageList::LanguageInfo.find(lan)}.compact.join(",")
    end
  end

  def linked_employees
    employer_profiles = EmployerProfile.find_by_general_agency_profile(self)
    emp_ids = employer_profiles.map(&:id)
    linked_employees = Person.where(:'employee_roles.employer_profile_id'.in => emp_ids)
  end

  def families
    employee_families = linked_employees.map(&:primary_family).to_a
    families = employee_families.uniq.compact
    families.sort_by{|f| f.primary_applicant.person.last_name}
  end

  def employer_clients_count
    employer_clients.present? ? employer_clients.count : 0
  end

  # general_agency should have only one general_agency_staff_role
  def primary_staff
    general_agency_staff_roles.present? ? general_agency_staff_roles.last : nil
  end

  def current_staff_state
    primary_staff.current_state
  rescue StandardError
    ""
  end

  def current_state
    aasm_state.humanize.titleize
  end

  def applicant?
    aasm_state == "is_applicant"
  end

  def general_agency_hired_notice(employer_profile)
    ShopNoticesNotifierJob.perform_later(self.id.to_s, "general_agency_hired_notice", employer_profile_id: employer_profile.id.to_s)
  rescue Exception => e
    (Rails.logger.error {"Unable to deliver general_agency_hired_notice to General Agency: #{self.legal_name} due to #{e}"}) unless Rails.env.test?
  end

  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.general_agency_profile }
    end

    def all
      list_embedded Organization.exists(general_agency_profile: true).order_by([:legal_name]).to_a
    end

    def all_by_broker_role(broker_role, options = {})
      favorite_general_agency_ids = begin
                                      broker_role.favorite_general_agencies.map(&:general_agency_profile_id)
                                    rescue StandardError
                                      []
                                    end
      all_ga = if options[:approved_only]
                 all.select{|ga| ga.aasm_state == 'is_approved'}
               else
                 all
               end

      if favorite_general_agency_ids.present?
        all_ga.sort {|ga| favorite_general_agency_ids.include?(ga.id) ? 0 : 1 }
      else
        all_ga
      end
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organization = BenefitSponsors::Organizations::Organization.where(
        "profiles._id" => BSON::ObjectId.from_string(id)
      ).first

      organization.profiles.where(id: BSON::ObjectId.from_string(id)).first if organization.present?
    end

    def filter_by(status = "is_applicant")
      if status == 'all'
        all
      else
        list_embedded Organization.exists(general_agency_profile: true).where(:'general_agency_profile.aasm_state' => status).order_by([:legal_name]).to_a
      end
    rescue StandardError
      []
    end
  end

  private

  def build_nested_models
    build_inbox if inbox.nil?
  end
end

# rubocop:enable all

