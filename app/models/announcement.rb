# frozen_string_literal: true

class Announcement
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include ::Config::SiteModelConcern

  AUDIENCE_KINDS = [].tap do |a|
    a << 'Employer' if is_shop_or_fehb_market_enabled?
    a << 'Employee' if is_shop_or_fehb_market_enabled?
    a << ['IVL', 'Broker', 'GA', 'Web_Page']
  end.flatten

  field :content, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :audiences, type: Array, default: []

  validates_presence_of :content, :start_date, :end_date
  validate :must_have_audiences
  validate :date_checks

  def must_have_audiences
    errors.add(:base, 'Please select at least one Audience') if audiences.blank?
  end

  def date_checks
    return if start_date.blank? || end_date.blank?
    errors.add(:base, "End Date should be later than today") if end_date < TimeKeeper.date_of_record
    errors.add(:base, "End Date should be later than Start date") if end_date < start_date
  end

  scope :current, ->{ where(:start_date.lte => TimeKeeper.date_of_record, :end_date.gte => TimeKeeper.date_of_record) }
  scope :by_audience, ->(value){ where(audiences: value) }

  def audiences_for_display
    audiences.join(',')
  end

  before_validation :update_audiences
  def update_audiences
    self.audiences = audiences.select(&:present?) if audiences.present?
  end

  before_validation :update_content
  def update_content
    self.content = content.strip if content.present?
  end

  class << self
    AUDIENCE_KINDS.each do |kind|
      define_method "current_msg_for_#{kind.downcase}".to_sym do
        Announcement.current.by_audience(kind).map(&:content)
      end
    end

    def audience_kinds
      AUDIENCE_KINDS
    end

    def get_announcements_by_portal(portal_path = "", person = nil)
      announcements = []

      if portal_path.include?("employers/employer_profiles")
        announcements.concat(Announcement.current_msg_for_employer)
      elsif portal_path.include?("families/home")
        announcements.concat(Announcement.current_msg_for_employee) if person&.has_active_employee_role?
        announcements.concat(Announcement.current_msg_for_ivl) if person&.is_consumer_role_active?
      elsif portal_path.include?("employee")
        announcements.concat(Announcement.current_msg_for_employee) if person&.has_active_employee_role?
      elsif portal_path.include?("consumer")
        announcements.concat(Announcement.current_msg_for_ivl) if person&.is_consumer_role_active?
      elsif portal_path.include?("broker_agencies")
        announcements.concat(Announcement.current_msg_for_broker)
      elsif portal_path.include?("general_agencies")
        announcements.concat(Announcement.current_msg_for_ga)
      end

      announcements.uniq
    end

    def announcements_for_web
      Announcement.current_msg_for_web_page
    end
  end
end
