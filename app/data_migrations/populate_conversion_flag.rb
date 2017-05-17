require File.join(Rails.root, "lib/mongoid_migration_task")

class PopulateConversionFlag< MongoidMigrationTask

  def migrate
    begin
      Organization.exists(:employer_profile => true).each do |org|
        employer_profile = org.employer_profile
        employer_profile.plan_years.each{|py| py.set(is_conversion: false)}

        if employer_profile.is_conversion?
          external_plan_years = employer_profile.plan_years.select{|py| py.coverage_period_contains?(employer_profile.registered_on)}
          external_plan_years.reject!{|py| py.draft? || py.canceled? || py.renewing_canceled?}

          if external_plan_years.blank?
            puts "missing external plan year #{employer_profile.fein}"
            next
          end

          if external_plan_years.size > 1
            puts "found multiple external plan years #{employer_profile.fein}"
            next
          end

          plan_years = employer_profile.plan_years.where({ 
            :aasm_state.nin => ['draft', 'renewing_canceled', 'canceled'],
            :start_on.lt => external_plan_years.first.start_on
          })

          external_plan_years += plan_years.select{|py|
            Family.where(:"households.hbx_enrollments" => {
              :$elemMatch => {
                :benefit_group_id.in => py.benefit_groups.map(&:id),
                :external_enrollment => true
                } }).any?
          }

          external_plan_years.each{|py| py.set(is_conversion: true)}
        end
      end
    rescue Exception => e
      puts e.message
    end
  end
end
