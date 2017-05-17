orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => Date.new(2017,6,1), :aasm_state => "renewing_draft"}}, :"employer_profile.profile_source" => 'conversion')

event_kind = ApplicationEventKind.where(:event_name => "conversion_group_renewal").first
notice_trigger = event_kind.notice_triggers.first

orgs.each do |org|
  emp = org.employer_profile
  begin
    builder = notice_trigger.notice_builder.camelize.constantize.new(emp, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
    puts "Delivered ==== #{emp.legal_name}"
  rescue Exception => e
    puts "Unable to deliver notice for #{emp.legal_name} =============== #{emp.fein}"
    puts "#{e.inspect}"
  end
end