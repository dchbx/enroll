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

    def remove_dup_override?
      ENV["remove_dup"].present? && ENV["remove_dup"] == "true"
    end

    def people
      #Return people who have outstanding verifications within the time specified
      people = Person.where(:"verification_types".elem_match => {
        "$and" => [
              { :validation_status => "outstanding"},
              { :updated_at => {'$gte'=>start_date, '$lte' => end_date} }
          ]  
        }
      )
    end


    def outstanding_types_for_person(person)
      #Return all outstanding types for person
      types = person.verification_types.where(
         :validation_status => "outstanding",
         :updated_at => {'$gte'=>start_date, '$lte' => end_date}
      )
    end

    def type_history(type)
      #Find all tranditions from [verified, pending] to outstanding ('reject' action)
      history_elements = type.type_history_elements.where(
        :action => 'reject',
        :updated_at => {'$gte'=>start_date, '$lte' => end_date}
      )
      
      #Only return latest one if removing duplicates
      remove_dup_override? ? [history_elements.sort_by{|type_history| type_history.updated_at}.last] : history_elements
    end

    report_prefix = remove_dup_override? ? "current" : "all"
    file_name = "#{Rails.root}/#{report_prefix}_outstanding_types_created_#{date.gsub(" ", "").split(",").join("_")}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      collect_rows = []
      people.each do |person|
        outstanding_types_for_person(person).each do |type|
          type_history(type).each do |type_history|     
            collect_rows << [
                    subscriber_id(person),
                    person.hbx_id,
                    person.first_name,
                    person.last_name,
                    type.type_name,
                    type_history.updated_at,
                    "outstanding",
                    type.due_date,
                    ivl_enrollment(person),
                    shop_enrollment(person)
                ]
          end
        end
      end

      collect_rows.each do |row|
        csv << row
      end
      puts "*********** DONE ******************"
    end

  end
end


