namespace :update_hbx do
  desc "update carrier_profile_id for hbx_enrollments"
  task :carrier_profile_id => :environment do 
    count = 0
    HbxEnrollment.where(carrier_profile_id: nil).each do |hbx_enrollment|
      if hbx_enrollment.plan_id.present?
        hbx_enrollment.update_attributes!(
          carrier_profile_id: hbx_enrollment.plan.try(:carrier_profile_id)
        ) 
        count += 1
      end
    end
    puts("Updated #{count} hbx_enrollments carrier_profile_id with plan carrier_profile_id.") unless Rails.env.test?
  end
end
