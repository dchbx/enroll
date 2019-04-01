module Notifier
  #Dependent service for UQHPAQHP of Projected Renewal Eligibility Notice
  class Services::DependentService

    attr_accessor :is_uqhp_notice, :payload_member, :age, :is_aqhp_eligible
    attr_accessor :person, :is_totally_ineligible, :is_uqhp_eligible
    attr_accessor :first_name, :last_name

    def initialize(is_uqhp_notice, member)
      @is_uqhp_notice = is_uqhp_notice
      @payload_member = member
      @person = person_details
      @first_name = f_name
      @last_name = l_name
      @age = calculate_age
      @is_totally_ineligible = totally_ineligible?
      @is_uqhp_eligible = uqhp_eligible?
      @is_aqhp_eligible = aqhp_eligible?
    end

    private

    def person_details
      Person.by_hbx_id(payload_member['person_hbx_id']).first
    end

    def f_name
      is_uqhp_notice ? person.first_name : payload_member['first_name']
    end

    def l_name
      is_uqhp_notice ? person.last_name : payload_member['last_name']
    end

    def calculate_age
      if is_uqhp_notice
        person.age_on(TimeKeeper.date_of_record).presence || nil
      else
        Date.current.year - Date.parse(payload_member['dob']).year
      end
    end

    def aqhp_eligible?
      is_uqhp_notice ? false : payload_member['aqhp_eligible'].casecmp('YES').zero?
    end

    def totally_ineligible?
      is_uqhp_notice ? false : payload_member['totally_inelig'].casecmp('YES').zero?
    end

    def uqhp_eligible?
      is_uqhp_notice.presence || payload_member['uqhp_eligible'].casecmp('YES').zero?
    end
  end
end
