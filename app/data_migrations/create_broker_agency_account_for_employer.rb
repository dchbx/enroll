class CreateBrokerAgencyAccountForEmployer < MongoidMigrationTask

  def migrate

    emp_org = Organization.where(:'employer_profile'.exists=>true, hbx_id: ENV['emp_hbx_id']).first
    br_agency_profile_org = Organization.where(:'broker_agency_profile'.exists=>true, hbx_id: ENV['br_agency_hbx_id']).first
    start_on = Date.strptime(ENV['br_start_on'].to_s, "%m/%d/%Y")

    if emp_org.present? && br_agency_profile_org.present?
      employer_profile=emp_org.employer_profile
      broker_agency_profile = br_agency_profile_org.broker_agency_profile
      broker = br_agency_profile_org.broker_agency_profile.brokers.select{|broker| broker.npn == ENV['br_npn']}.first
      if broker_agency_profile.present? && broker.present?
        employer_profile.broker_agency_accounts.build(broker_agency_profile_id:broker_agency_profile.id, start_on:start_on, writing_agent_id:broker.id)
        employer_profile.save!
      else
        puts "Broker not found" unless Rails.env.test? &&  broker.blank?
        puts "Broker agency profile not found" unless Rails.env.test? &&  broker_agency_profile.blank?
      end
    else
      puts "Employer organization not found" unless Rails.env.test? &&  emp_org.blank?
      puts "Broker agency organization not found" unless Rails.env.test? &&  br_agency_profile_org.blank?
    end
  end
end