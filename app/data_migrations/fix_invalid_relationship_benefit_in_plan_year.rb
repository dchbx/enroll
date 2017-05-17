require File.join(Rails.root, "lib/mongoid_migration_task")

class FixInvalidRelationshipBenefitInPlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.no_timeout.where("employer_profile" => {"$exists" => true})
    organizations.each do |org|
      org.employer_profile.plan_years.each do |plan_year|
        plan_year.benefit_groups.map(&:relationship_benefits).flatten.select{|r| r.relationship == "child_26_and_over"}.each do |child_over_26_relationship|
          if child_over_26_relationship.offered
            child_over_26_relationship.update_attribute(:offered, false)
            puts "#{org.employer_profile.legal_name} child_over_26_relationship_benefit updated" unless Rails.env.test?
          end
        end
      end
    end
  end
end
