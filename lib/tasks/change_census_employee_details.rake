require File.join(Rails.root, "app", "data_migrations", "change_census_employee_details")
# This rake task is to change the attributes on census_employee
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_details action="update_employment_terminated_on" employer_fein=123456789 terminated_on=20171001  ssns="000111001,332199875"

# To change the SSN on census record
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_details action="change_ssn" encrypted_ssn="ZCVGGZG+_DUD+==JKLS" new_encrypted_ssn="CVGGZG+_DUD+==JKLSHH"

# To delink employee role
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_details action="delink_employee_role" encrypted_ssn="ZCVGGZG+_DUD+==JKLS"

# To link or construct employee role
# RAILS_ENV=production bundle exec rake migrations:change_census_employee_details action="link_or_construct_employee_role" encrypted_ssn="ZCVGGZG+_DUD+==JKLS"

namespace :migrations do
  desc "changing attributes on census_employee"
  ChangeCensusEmployeeDetails.define_task :change_census_employee_details => :environment
end
