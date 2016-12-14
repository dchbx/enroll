require File.join(Rails.root, "app", "data_migrations", "count_enrollments")

#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

namespace :count_enrollments do
  desc 'set initial counts correctly for enrollments'
  CountEnrollments.define_task :get_counts => :environment
end


#RAILS_ENV=production rake count_enrollments:get_counts
