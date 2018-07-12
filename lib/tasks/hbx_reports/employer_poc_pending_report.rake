# Generate report for all employer POCs pending for approval
# To run this rake - RAILS_ENV=production bundle exec rake shop:employer_poc_pending_report

namespace :shop do
  desc "Print out employer pending POCs"
  task :employer_poc_pending_report => :environment do
    include Config::AcaHelper

    roles = Person.where(:employer_staff_roles.exists => true).map(&:employer_staff_roles).flatten
    pending = roles.select{|role| role.aasm_state == 'is_applicant'}
    file_name = fetch_file_format('er_poc_pending_app_report', 'ERPOCPENDINGAPP')

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << ['ER POC Applicant Name','ER POC Email Address','ER Legal Name','ER FEIN','ER POC Application Date Time']
      pending.each do |role|
        org =  BenefitSponsors::Organizations::Organization.by_employer_profile(role.benefit_sponsor_employer_profile_id).first
        csv << [role.person.full_name, role.person.work_email_or_best, org.legal_name, org.fein, role.updated_at.to_s]
      end
    end
    
    if Rails.env.production?
      pubber = Publishers::Legacy::EmployerPocPendingReportPublisher.new
      pubber.publish URI.join("file://", file_name)
    end
  end
end
