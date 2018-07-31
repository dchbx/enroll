require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class ShopEnrollmentReport < MongoidMigrationTask
  def migrate

    if ENV['purchase_date_start'].blank? && ENV['purchase_date_end'].blank?
      # Purchase dates are from 10 weeks to todays date
      purchase_date_start = (Time.now - 2.month - 8.days).beginning_of_day 
      purchase_date_end = (Time.now).end_of_day
    else 
      purchase_date_start = Time.strptime(ENV['purchase_date_start'],'%m/%d/%Y').beginning_of_day 
      purchase_date_end = Time.strptime(ENV['purchase_date_end'],'%m/%d/%Y').end_of_day
    end
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")

    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shopping_completed
    qs.eliminate_family_duplicates

    qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => purchase_date_start, "$lte" => purchase_date_end}}})
    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip) if File.exists?("all_glue_policies.txt")

    enrollment_ids_final = qs.evaluate.inject([]) do |result, r|
      result << r['hbx_id']
      result
    end

    field_names = ['Employer ID', 'Employer FEIN', 'Employer Name', 'Employer Plan Year Start Date', 'Plan Year State', 'Employer State', 'Enrollment Group ID', 
               'Enrollment Purchase Date/Time', 'Coverage Start Date', 'Enrollment State', 'Subscriber HBX ID', 'Subscriber First Name','Subscriber Last Name', 'Subscriber SSN', 'Plan HIOS Id', 'Covered lives on the enrollment', 'Enrollment Reason', 'In Glue']

    file_name = "#{Rails.root}/hbx_report/shop_enrollment_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      enrollment_ids_final.each do |id|
        hbx_enrollment = HbxEnrollment.by_hbx_id(id).first
        begin
          employer_profile = hbx_enrollment.employer_profile
          case hbx_enrollment.enrollment_kind
          when "special_enrollment" 
            enrollment_reason = hbx_enrollment.special_enrollment_period.qualifying_life_event_kind.reason
          when "open_enrollment"
            enrollment_reason = hbx_enrollment.eligibility_event_kind
          end
          employer_id = employer_profile.hbx_id
          fein = employer_profile.fein
          legal_name = employer_profile.legal_name
          plan_year = hbx_enrollment.sponsored_benefit_package.benefit_application
          plan_year_start = plan_year.start_on.to_s
          plan_year_state = plan_year.aasm_state
          employer_profile_aasm = plan_year.benefit_sponsorship.aasm_state
          eg_id = id
          purchase_time = hbx_enrollment.created_at
          coverage_start = hbx_enrollment.effective_on
          enrollment_state = hbx_enrollment.aasm_state 
          subscriber = hbx_enrollment.subscriber
          covered_lives = hbx_enrollment.hbx_enrollment_members.size
          plan_hios_id = hbx_enrollment.product.hios_id
          if subscriber.present? && subscriber.person.present?
            person = subscriber.person
            subscriber_hbx_id = subscriber.hbx_id
            first_name = person.first_name
            last_name = person.last_name
            subscriber_ssn = person.ssn
          end
          in_glue = glue_list.include?(id) if glue_list.present?
          csv << [employer_id,fein,legal_name,plan_year_start,plan_year_state,employer_profile_aasm,eg_id,purchase_time,coverage_start,enrollment_state,subscriber_hbx_id,first_name,last_name,subscriber_ssn,plan_hios_id,covered_lives,enrollment_reason,in_glue]
        rescue Exception => e
          puts "Couldnot add the hbx_enrollment's information on to the CSV, because #{e.inspect}" unless Rails.env.test?
        end
      end
    end

    puts "Shop Enrollment Report Generated" unless Rails.env.test?
  end
end