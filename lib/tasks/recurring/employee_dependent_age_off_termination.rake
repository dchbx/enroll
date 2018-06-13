namespace :recurring do
  #used congressional and non-congressional event names based on  dc to work in both DC and MA
  # As per business request - Do not use this rake task in MA. This rake task needs to be run only in DC. In MA, its Manual.
  desc "An automation rake task that sends out dependent age off termination notifications to congressional and non congressional employees"
  task employee_dependent_age_off_termination: :environment do
    new_date = TimeKeeper.date_of_record
    if new_date.mday == 1
      Family.all_with_multiple_family_members.by_enrollment_shop_market.each do |family|
        begin
          primary_person = family.primary_applicant.person
          trigger_dep_age_off_notice(primary_person)
        rescue => e
          Rails.logger.error {"Unable to deliver employee_dependent_age_off_termination notice to: #{family.primary_applicant.person.hbx_id} due to #{e.backtrace}"}
        end
      end
    end
  end

  # RAILS_ENV=production bundle exec rake recurring:dependent_age_off_termination_notification_manual['48574857']
  desc "Manual rake task used to send dependent age off termination notifications to employees"
  task :dependent_age_off_termination_notification_manual, [:hbx_id] => :environment do |task, args|
    return unless args[:hbx_id].present?
    begin
      primary_person = Person.where(:hbx_id => args[:hbx_id].to_s).first
      trigger_dep_age_off_notice(primary_person)
    rescue Exception => e
      Rails.logger.error {"Unable to deliver employee_dependent_age_off_termination notice to: #{primary_person.hbx_id} due to #{e.backtrace}"}
    end
  end

  def trigger_dep_age_off_notice(person)
    new_date = TimeKeeper.date_of_record
    employee_roles = person.active_employee_roles
    employee_roles.each do |employee_role|
      next if (employee_role.benefit_group.nil?)
      ben_grp = employee_role.benefit_group.is_congress
      hbx_enrollments = employee_role.census_employee.active_benefit_group_assignment.hbx_enrollments
      enrollments = hbx_enrollments.select{|e| (HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).include?(e.aasm_state)}
      if enrollments.present?
        covered_members = enrollments.inject([]) do |covered_members, enrollment|
          covered_members += enrollment.hbx_enrollment_members.map(&:family_member).map(&:person)
        end.uniq
        covered_members_ids = covered_members.flat_map(&:_id)
        relations = person.person_relationships.select{ |rel| (covered_members_ids.include? rel.relative_id) && (rel.kind == "child")}
        if relations.present?
          aged_off_dependents = relations.select{|dep| (new_date.month == (dep.relative.dob.month)) && (dep.relative.age_on(new_date.end_of_month) >= 26)}.flat_map(&:relative)
          next if aged_off_dependents.empty?
          dep_hbx_ids = aged_off_dependents.map(&:hbx_id)
          event_name = ben_grp ? "employee_notice_dependent_age_off_termination_congressional" : "employee_notice_dependent_age_off_termination_non_congressional"
          observer = Observers::NoticeObserver.new
          observer.deliver(recipient: employee_role, event_object: employee_role.census_employee, notice_event: event_name,  notice_params: {dep_hbx_ids: dep_hbx_ids})
          puts "Delivered employee_dependent_age_off_termination notice to #{employee_role.census_employee.full_name}" unless Rails.env.test?
        end
      end
    end
  end
end