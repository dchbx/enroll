require File.join(Rails.root, "app", "data_migrations", "change_er_to_applicant_state")

# RAILS_ENV=production bundle exec rake migrations:change_er_to_applicant_state feins='042266782 042919603 593832832 204245950 475178250 202104454 455416547 042839683 042424820 471805382 510486590 454678255 043637716 464474504 263934159 042857550 043281393 453557994 462608718 043126642 454652531 043304489 421695917 043545180' plan_year_state="canceled"

namespace :migrations do
  desc "change employer profile to applicant state"
  ChangeErToApplicantState.define_task :change_er_to_applicant_state => :environment
end 
