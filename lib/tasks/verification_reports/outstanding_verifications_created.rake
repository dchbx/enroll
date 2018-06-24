require 'csv'

# Both reports outlined in 21119 and 21123 will utilize the same rake task.
# For 21123 we will have an additional switch to remove Duplicates.

# 21119 - Include Duplicates (Report Filename: all_outstanding_types_created_[Month]_[Year].csv)
# # RAILS_ENV=production bundle exec rake reports:outstanding_types_created date=Month,Year (example: January,2018)

# 21123 - Remove Duplicates (Report Filename: current_outstanding_types_created_[Month]_[Year].csv)
# # RAILS_ENV=production bundle exec rake reports:outstanding_types_created date=Month,Year remove_dup=true

namespace :reports do
  desc "Outstanding verifications created monthly report"
  task :outstanding_types_created => :environment do
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFICATION_TYPE TRANSITION OUTSTANDING DUE_DATE IVL_ENROLLMENT SHOP_ENROLLMENT)

    def date
      begin
        ENV["date"].strip
      rescue
        puts 'Provide report month.'
      end
    end

    def ivl_enrollment(person)
      if person.primary_family
        if person.primary_family.active_household.hbx_enrollments.individual_market.present?
          person.primary_family.active_household.hbx_enrollments.individual_market.select{|enrollment| enrollment.currently_active? }.any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.active_household.hbx_enrollments.individual_market.present?}
        enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| !(["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state)}
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end

    def shop_enrollment(person)
      if person.primary_family
        if person.primary_family.active_household.hbx_enrollments.shop_market.present?
          person.primary_family.active_household.hbx_enrollments.shop_market.select{|enrollment| enrollment.currently_active? }.any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.active_household.hbx_enrollments.shop_market.present?}
        enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| (["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select{|enrollment| enrollment.currently_active?}
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end

    def subscriber_id(person)
      if person.primary_family
        person.hbx_id
      else
        primary = person.families.map(&:primary_family_member).select{|member| member.person.consumer_role.present?}.first || person.families.map(&:primary_family_member).first
        primary ? primary.hbx_id : person.hbx_id
      end
    end

    def start_date
      Date.parse(date)
    end

    def end_date
      Date.parse(date).next_month
    end

    def due_date_for_type(person, type, transition)
      if person.consumer_role.special_verifications.any?
        sv = person.consumer_role.special_verifications.order_by(:created_at => 'desc').select{|sv| sv.verification_type == type }.select{|svp| svp.created_at < end_date}.first
        sv.present? ? sv.due_date : transition.transition_at + 95.days
      else
        transition.transition_at + 95.days
      end
    end

    def get_rejected_type(person)
      record = person.consumer_role.verification_type_history_elements.where(:action => "return for deficiency", :created_at=>{'$gte'=>start_date, '$lte' => end_date}).first
      record.verification_type if record
    end

    def remove_dup_override?
      ENV["remove_dup"].present? && ENV["remove_dup"] == "true"
    end

    def people
      people = Person.where(:"consumer_role.workflow_state_transitions".elem_match => {
          "$and" => [
              {:event => {"$in" => ["ssn_invalid!",
                                    "ssn_valid_citizenship_invalid!",
                                    "fail_dhs!",
                                    "fail_residency!",
                                    "reject!",
                                    "coverage_purchased!"] }},
              { :transition_at.gte => start_date },
              { :transition_at.lte => end_date }
          ]
      })

      remove_dup_override? ? people.where(:"consumer_role.aasm_state" => "verification_outstanding") : people
    end

    def workflow_transitions(person)
      transitions_no_ssn = person.consumer_role.workflow_state_transitions.where(:event => "coverage_purchased!", :to_state => "verification_outstanding", :transition_at => {'$gte'=>start_date, '$lte' => end_date}).to_a.uniq{|t| t.created_at.to_date}

      transitions_reject = person.consumer_role.workflow_state_transitions.where(:event => "reject!", :transition_at => {'$gte'=>start_date, '$lte' => end_date}).to_a.uniq{|t| t.created_at.to_date}

      transitions_dc = person.consumer_role.workflow_state_transitions.where(:event => "fail_residency!", :transition_at => {'$gte'=>start_date, '$lte' => end_date}).to_a.uniq{|t| t.created_at.to_date}

      transitions_ssn = person.consumer_role.workflow_state_transitions.where(:event => "ssn_invalid!", :transition_at => {'$gte'=>start_date, '$lte' => end_date}).to_a.uniq{|t| t.created_at.to_date}

      transitions_cit = person.consumer_role.workflow_state_transitions.where(:event => {"$in" => ["ssn_valid_citizenship_invalid!", "fail_dhs!"]},
                                                                              :transition_at => {'$gte'=>start_date, '$lte' => end_date}).to_a.uniq{|t| t.created_at.to_date}

      transitions = transitions_reject + transitions_dc + transitions_ssn + transitions_cit + transitions_no_ssn

      remove_dup_override? ? transitions.sort_by{|t| t.created_at}.reverse.uniq{|e| e.event} : transitions
    end

    report_prefix = remove_dup_override? ? "current" : "all"
    file_name = "#{Rails.root}/#{report_prefix}_outstanding_types_created_#{date.gsub(" ", "").split(",").join("_")}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      collect_rows = []
      people.each do |person|
        if workflow_transitions(person).any?
          workflow_transitions(person).each do |transition|
            case transition.event
            when "ssn_invalid!"
              types = person.verification_types - ['DC Residency', 'American Indian Status']
            when "ssn_valid_citizenship_invalid!"
              types = (person.verification_types - ['DC Residency', 'Social Security Number', 'American Indian Status'])
            when "fail_dhs!"
              types = (person.verification_types - ['DC Residency', 'Social Security Number', 'American Indian Status'])
            when "fail_residency!"
              types = ["DC Residency"]
            when "reject!"
              types = [get_rejected_type(person)]
            when "coverage_purchased!"
              types = person.verification_types - ['DC Residency', 'American Indian Status']
            end

            types.each do |type|
              collect_rows << [
                  subscriber_id(person),
                  person.hbx_id,
                  person.first_name,
                  person.last_name,
                  type,
                  transition.transition_at,
                  "outstanding",
                  due_date_for_type(person, type, transition).to_date,
                  ivl_enrollment(person),
                  shop_enrollment(person)
              ]
            end
          end
        end
      end
      rows_for_csv = remove_dup_override? ? collect_rows.uniq{|row| [row[2], row[4]] } : collect_rows

      rows_for_csv.each do |row|
        csv << row
      end
      puts "*********** DONE ******************"
    end

  end
end


