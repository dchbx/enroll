require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class OutstandingTypesReport < MongoidMigrationTask
  def ivl_enrollment(person)
    if person.primary_family
      if person.primary_family.active_household.hbx_enrollments.individual_market.present?
        person.primary_family.active_household.hbx_enrollments.individual_market.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year) }.any? ? "YES" : "NO"
      else
        "nil"
      end
    else
      families = person.families.select{|family| family.active_household.hbx_enrollments.individual_market.present?}
      enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| !(["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
      all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
      active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year)}
      return "nil" unless all_enrollments.any?
      active_enrollments.any? ? "YES" : "NO"
    end
  end

  def outstanding_types(person)
    person.verification_types.active.find_all do |type|
      type.is_type_outstanding?
    end
  end

  def created_at(person)
    transition = person.consumer_role.workflow_state_transitions.where(:to_state => "verification_outstanding").order_by(:created_at => 'desc').first
    if transition
      transition.transition_at
    else
      person.consumer_role.created_at
    end
  end

  def shop_enrollment(person)
    if person.primary_family
      if person.primary_family.active_household.hbx_enrollments.shop_market.present?
        person.primary_family.active_household.hbx_enrollments.shop_market.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year) }.any? ? "YES" : "NO"
      else
        "nil"
      end
    else
      families = person.families.select{|family| family.active_household.hbx_enrollments.shop_market.present?}
      enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| (["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
      all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
      active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year)}
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

  def due_date_for_type(type)
    type.due_date ||  TimeKeeper.date_of_record + 95.days
  end

  def no_active_enrollments(person)
    return true if person.families.empty?
    person.families.select{|f| f.person_has_an_active_enrollment?(person)}.empty?
  end

  def people
    Person.where(:"verification_types.validation_status" => "outstanding")
  end

  def migrate
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFICATION_TYPE TRANSITION OUTSTANDING DUE_DATE IVL_ENROLLMENT SHOP_ENROLLMENT)
    file_name = "#{Rails.root}/app/reports/outstanding_types_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      people.each do |person|
        begin
          next if no_active_enrollments(person)
          if outstanding_types(person).any?
            outstanding_types(person).each do |type|
              csv << [  subscriber_id(person),
                        person.hbx_id,
                        person.first_name,
                        person.last_name,
                        type.type_name,
                        created_at(person).to_date,
                        "yes",
                        due_date_for_type(type).to_date,
                        ivl_enrollment(person),
                        shop_enrollment(person)
                      ]
            end
          end
        rescue => e
          puts "Invalid Person with HBX_ID: #{person.hbx_id}"
        end
      end
    end
    puts "*********** DONE ******************" unless Rails.env.test?
  end
end
