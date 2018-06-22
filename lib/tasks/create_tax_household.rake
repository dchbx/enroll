#This rake task will create new thh and eligibility determinations with the given max aptc and csr and source field will be stored as admin_script

namespace :task do
  desc "Create tax household with aptc and csr"
  task :create_thh_and_eligibility => :environment do

    ssn = ENV['ssn']
    hbx_id = ENV['hbx_id'].to_s
    max_aptc = ENV['max_aptc'].to_s
    csr = ENV['csr'].to_s
    date = ENV['effective_date']
    slcsp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id

    effective_date = date.to_date

    if ssn.present? && ssn =~ /^\d+$/ && ssn.to_s != '0'
      ssn = '0'*(9-ssn.length) + ssn if ssn.length < 9
      person = Person.by_ssn(ssn).first rescue nil
    end

    unless person
      person = Person.by_hbx_id(hbx_id).first rescue nil
    end

    if person.present?
      return unless person.primary_family
      active_household = person.primary_family.active_household
      active_household.build_thh_and_eligibility(max_aptc, csr, effective_date, slcsp)
      puts "THH & Eligibility created successfully" unless Rails.env.test?
    else
      puts "No Person Record Found with hbx_id #{hbx_id}" unless Rails.env.test?
    end
  end
end
