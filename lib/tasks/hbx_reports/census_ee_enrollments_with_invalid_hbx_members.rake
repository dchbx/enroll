# list hbx enrollments of census employees who included family members in hbx enrollment, When employer has unchecked family members in plan year.
require 'csv'

namespace :reports do
  namespace :shop do

    desc "hbx_enrollments of census employees with invalid enrollment members."
    task :census_ee_invalid_enrollments => :environment do

      familys=Family.by_enrollment_shop_market

      field_names  = %w(
          member_name
        )

      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/census_ee_invalid_enrollments.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        familys.each do |family|
          next if family.enrollments.blank?
          family.enrollments.each do |enrollment|
            members=enrollment.hbx_enrollment_members.select{|member| !eligible_enrollment_member?(member,enrollment) }
            members.each do |member|
              member.family_member.person.first_name

            end if enrollment.kind =='employer_sponsored' && members.present?
          end
        end
      end
    end
  end
end

# def valid_enrollment?(enrollment)
#   relationship_benefits=enrollment.benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
#   enrollment.hbx_enrollment_members.inject([]) do |offered, member|
#     relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
#     offered << relationship_benefits.include?(relationship)
#   end
#   offered.all?
# end

def eligible_enrollment_member?(member,enrollment)
  relationship_benefits=enrollment.benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
  relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
  relationship = "child_over_26" if relationship == "child_under_26" && member.person.age_on(@plan_year_start_on) >= 26
  (relationship_benefits.include?(relationship))
end