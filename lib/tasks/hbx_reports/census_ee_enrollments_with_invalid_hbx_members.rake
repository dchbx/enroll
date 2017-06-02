# list invalid hbx_enrollment_members of census employees who included members in hbx enrollment, When employer has not sponsorsed for members in plan year.
#To run rake task: RAILS_ENV=production rake reports:shop:census_ee_invalid_enrollments

require 'csv'

namespace :reports do
  namespace :shop do

    desc "hbx_enrollments of census employees with invalid hbx_enrollment_members."
    task :census_ee_invalid_enrollments => :environment do

      familys=Family.by_enrollment_shop_market

      field_names  = %w(
        Primary_FirstName
        Primary_LastName
        Primary_Member_HBX
        Ineligible_Dependent_FirstName
        Ineligible_Dependent_LastName
        Ineligible_Dependent_HBX
        Enrollment_HBX
        Enrollment_State
        )

      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/census_ee_invalid_enrollments.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        familys.each do |family|
          next if family.enrollments.blank?
          family.enrollments.shop_market.enrolled_and_renewal.each do |enrollment|
            enrollment.hbx_enrollment_members.select{|hbx_member| !eligible_enrollment_member?(hbx_member,enrollment)}.each do |member|
              if member.present?
                csv << [
                    enrollment.subscriber.person.first_name,
                    enrollment.subscriber.person.last_name,
                    enrollment.subscriber.person.hbx_id,
                    member.person.first_name,
                    member.person.last_name,
                    member.person.hbx_id,
                    enrollment.hbx_id,
                    enrollment.aasm_state
                ]
              end
            end
          end
        end
      end
    end
  end
end

def eligible_enrollment_member?(hbx_member,enrollment)
  relationship_benefits = enrollment.try(:benefit_group).present? ? enrollment.benefit_group.relationship_benefits.select(&:offered).map(&:relationship) : []
  relationship = PlanCostDecorator.benefit_relationship(hbx_member.primary_relationship)
  return false if relationship == "child_under_26" && hbx_member.person.age_on(enrollment.effective_on) >= 26
  (relationship_benefits.include?(relationship))
end