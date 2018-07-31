require 'csv'

# The idea behind this report is to get a list of all of the enrollments for an employer and what is currently in Glue. 
# Steps
# 1) You need to pull a list of enrollments from glue (bundle exec rails r script/queries/print_all_policy_ids > all_glue_policies.txt -e production)
# 2) Place that file into the Enroll Root directory. 
# 3) Run the below rake task
# RAILS_ENV=production bundle exec rake reports:outstanding_monthly_enrollments start_date='04/01/2018'

namespace :reports do 

  desc "Outstanding Enrollments by Employer"
  task :outstanding_monthly_enrollments => :environment do
    effective_on = Date.strptime(ENV['start_date'],'%m/%d/%Y') 

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")

    def quiet_period_range(benefit_application,effective_on)
      start_on = benefit_application.open_enrollment_period.max.to_date
      if benefit_application.predecessor.present?
        end_on = benefit_application.renewal_quiet_period_end(effective_on)
      else
        end_on = benefit_application.initial_quiet_period_end(effective_on)
      end 
      return start_on..end_on
    end

    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)

    field_names = ['Employer ID', 'Employer FEIN', 'Employer Name','Open Enrollment Start', 'Open Enrollment End', 'Employer Plan Year Start Date', 'Plan Year State', 
                   'Employer State', 'Initial/Renewal?', 'Binder Paid?', 'Enrollment Group ID', 'Carrier', 'Plan', 'Enrollment Purchase Date/Time', 'Coverage Start Date', 'Enrollment State', 'Subscriber HBX ID', 
                   'Subscriber First Name','Subscriber Last Name','Policy in Glue?', 'Quiet Period?']
    CSV.open("#{Rails.root}/hbx_report/#{effective_on.strftime('%Y%m%d')}_employer_enrollments_#{Time.now.strftime('%Y%m%d%H%M')}.csv","w") do |csv|
      csv << field_names
      benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({"benefit_applications" => {"$elemMatch" => {"effective_period.min" => effective_on}}})
      benefit_applications = benefit_sponsorships.to_a.flat_map(&:benefit_applications).to_a.select{|ba| ba.effective_period.min == effective_on}
      enrollment_ids = benefit_applications.flat_map(&:hbx_enrollments).map(&:hbx_id).compact.uniq
      enrollment_ids.each do |id|
        begin
        hbx_enrollment = HbxEnrollment.by_hbx_id(id).first
        benefit_sponsorship = hbx_enrollment.benefit_sponsorship
        employer_id = benefit_sponsorship.hbx_id
        fein = benefit_sponsorship.organization.fein
        legal_name = benefit_sponsorship.organization.legal_name
        benefit_application = hbx_enrollment.sponsored_benefit_package.benefit_application
        oe_start = benefit_application.open_enrollment_period.min
        oe_end = benefit_application.open_enrollment_period.max
        benefit_application_start = benefit_application.effective_period.min.to_s
        benefit_application_state = benefit_application.aasm_state
        benefit_sponsorship_aasm = benefit_sponsorship.aasm_state
        initial_renewal = benefit_application.predecessor.present? ? "renewal" : "initial"
        binder_paid = %w(initial_enrollment_eligible active).include?(benefit_sponsorship_aasm.to_s)
        eg_id = id
        product = hbx_enrollment.product.title rescue ""
        carrier = product.issuer_profile.legal_name rescue ""
        purchase_time = hbx_enrollment.created_at
        coverage_start = hbx_enrollment.effective_on
        enrollment_state = hbx_enrollment.aasm_state 
        subscriber = hbx_enrollment.subscriber
        if subscriber.present? && subscriber.person.present?
          subscriber_hbx_id = subscriber.hbx_id
          first_name = subscriber.person.first_name
          last_name = subscriber.person.last_name
        end
        in_glue = glue_list.include?(id)
        qp = quiet_period_range(benefit_application,effective_on)
        quiet_period_boolean = qp.include?(hbx_enrollment.created_at)
        csv << [employer_id,fein,legal_name,oe_start,oe_end,benefit_application_start,benefit_application_state,benefit_sponsorship_aasm,initial_renewal,binder_paid,eg_id,carrier,product,purchase_time,coverage_start,
                enrollment_state,subscriber_hbx_id,first_name,last_name,in_glue, quiet_period_boolean]
        rescue Exception => e
          puts "#{id} - #{e.inspect}"
          next
        end
      end
    end
  end
end