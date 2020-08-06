# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class OutstandingMonthlyEnrollments < MongoidMigrationTask
  include Config::AcaHelper

  def get_enrollment_ids(benefit_applications)
    benefit_applications.inject([]) do |ids, ba|
      families = Family.unscoped.where(:_id.in => HbxEnrollment.where(
        :sponsored_benefit_package_id => { "$in" => ba.benefit_packages.pluck(:_id) },
        :aasm_state => { "$nin" => %w[coverage_canceled shopping coverage_terminated] }
      )
                                        .pluck(:family_id))

      id_list = ba.benefit_packages.collect(&:_id).uniq
      enrs = families.inject([]) do |enrollments, family|
        enrollments << family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in => id_list).enrolled_and_renewing.to_a
        enrollments.flatten.compact.uniq
      end
      ids += enrs.map(&:hbx_id)
      ids.flatten.compact.uniq
    end
  end

  def migrate
    effective_on = Date.strptime(ENV['start_date'],'%m/%d/%Y')
    file_name = "#{Rails.root}/hbx_report/#{effective_on.strftime('%Y%m%d')}_employer_enrollments_#{Time.now.strftime('%Y%m%d%H%M')}.csv"
    Dir.mkdir("hbx_report") unless File.exist?("hbx_report")

    def quiet_period_range(benefit_application,effective_on)
      start_on = benefit_application.open_enrollment_period.max.to_date
      end_on = if benefit_application.predecessor.present?
                 benefit_application.renewal_quiet_period_end(effective_on)
               else
                 benefit_application.initial_quiet_period_end(effective_on)
               end
      (start_on..end_on)
    end

    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip) if File.exist?("all_glue_policies.txt")
    field_names = ["Employer ID",
                   "Employer FEIN",
                   "Employer Name",
                   "Open Enrollment Start",
                   "Open Enrollment End",
                   "Employer Plan Year Start Date",
                   "Plan Year State",
                   "Covered Lives",
                   "Enrollment Reason",
                   "Employer State",
                   "Initial/Renewal?",
                   "Binder Paid?",
                   "Enrollment Group ID",
                   "Carrier",
                   "Plan",
                   "Plan Hios ID",
                   "Enrollment Purchase Date/Time",
                   "Coverage Start Date",
                   "Enrollment State",
                   "Subscriber HBX ID",
                   "Subscriber First Name",
                   "Subscriber Last Name",
                   "Policy in Glue?",
                   "Quiet Period?"]

    CSV.open(file_name,"w") do |csv|
      csv << field_names
      benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({"benefit_applications" => {"$elemMatch" => {"effective_period.min" => effective_on}}})
      benefit_applications = benefit_sponsorships.to_a.flat_map(&:benefit_applications).to_a.select{|ba| ba.effective_period.min == effective_on}
      enrollment_ids = get_enrollment_ids(benefit_applications)
      # enrollment_ids = benefit_applications.flat_map(&:hbx_enrollments).map(&:hbx_id).compact.uniq
      enrollment_ids.each do |id|

        hbx_enrollment = HbxEnrollment.by_hbx_id(id).first
        case hbx_enrollment.enrollment_kind
        when "special_enrollment"
          enrollment_reason = hbx_enrollment.special_enrollment_period.qualifying_life_event_kind.reason
        when "open_enrollment"
          enrollment_reason = hbx_enrollment.eligibility_event_kind
        end
        covered_lives = hbx_enrollment.hbx_enrollment_members.size
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
        binder_paid = %w[initial_enrollment_eligible active].include?(benefit_sponsorship_aasm.to_s)
        eg_id = id
        product = begin
                    hbx_enrollment.product
                  rescue StandardError
                    ""
                  end
        carrier = begin
                    product.issuer_profile.legal_name
                  rescue StandardError
                    ""
                  end
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
        csv << [employer_id,fein,legal_name,oe_start,oe_end,benefit_application_start,benefit_application_state, covered_lives, enrollment_reason,benefit_sponsorship_aasm,initial_renewal,binder_paid,eg_id,carrier,product.title, product.hios_id,purchase_time,coverage_start,
                enrollment_state,subscriber_hbx_id,first_name,last_name,in_glue, quiet_period_boolean]
      rescue Exception => e
        puts "#{id} - #{e.inspect}" unless Rails.env.test?
        next

      end

      if Rails.env.production?
        pubber = Publishers::Legacy::OutstandingMonthlyEnrollmentsReportPublisher.new
        pubber.publish URI.join("file://", file_name)
      end

      if File.exist?(file_name)
        puts 'Report has been successfully generated in the hbx_report directory!' unless Rails.env.test?
      end
    end
  end
end