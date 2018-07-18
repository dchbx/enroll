class PlanDesignOrganizationMigration < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/plan_design_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( plan_design_org_name plan_design_org_id status owner_profile_id sponsor_profile_id)

      logger = Logger.new("#{Rails.root}/log/plan_design_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        update_plan_design_organization(csv, logger)

        puts "" unless Rails.env.test?
        puts "Check plan_design_migration_data logs & plan_design_migration_status csv for additional information." unless Rails.env.test?

      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.update_plan_design_organization(csv, logger)

    pdos = SponsoredBenefits::Organizations::PlanDesignOrganization.all
    emp_orgs = BenefitSponsors::Organizations::Organization.employer_profiles
    new_bk_orgs = BenefitSponsors::Organizations::Organization.broker_agency_profiles
    old_bk_orgs =  Organization.has_broker_agency_profile

    #counters
    total = 0
    success = 0
    failed = 0

    pdos.batch_size(1000).no_timeout.all.each do |pdo|

      next unless (pdo.owner_profile_class_name == "::BrokerAgencyProfile")

      total += 1

      begin

        emp_org = emp_orgs.employer_by_fein(pdo.fein).first

        if pdo.sponsor_profile_id.present? && emp_org.present?
          sponsor_profile_id = emp_org.employer_profile.id
        end

        old_bk_org = old_bk_orgs.where(:"broker_agency_profile._id" => pdo.owner_profile_id).first

        if old_bk_org.present?
          new_org = new_bk_orgs.broker_by_hbx_id(old_bk_org.hbx_id).first
          if new_org.present?
            owner_profile_id = new_org.broker_agency_profile._id
          end
        end

        if owner_profile_id.present?
          pdo.past_owner_profile_id = pdo.owner_profile_id
          pdo.past_owner_profile_class_name = pdo.owner_profile_class_name
          pdo.past_sponsor_profile_id = pdo.sponsor_profile_id
          pdo.past_sponsor_profile_class_name = pdo.sponsor_profile_class_name
          pdo.save!(validate: false)

          pdo.owner_profile_id = owner_profile_id
          pdo.owner_profile_class_name = "::BenefitSponsors::Organizations::Profile"
          pdo.sponsor_profile_id = sponsor_profile_id if sponsor_profile_id.present?
          pdo.sponsor_profile_class_name = "::BenefitSponsors::Organizations::Profile" if sponsor_profile_id.present?
          pdo.save!(validate: false)
          success += 1
          print '.' unless Rails.env.test?
          csv << [pdo.legal_name, pdo.id, "updated", pdo.owner_profile_id, pdo.sponsor_profile_id]
        else
          failed += 1
          print 'S' unless Rails.env.test?
          csv << [pdo.legal_name, pdo.id, "skipped as no matching owner_profile_id present in new model", pdo.owner_profile_id, pdo.sponsor_profile_id]
        end

      rescue Exception => e
        failed += 1
        print 'F' unless Rails.env.test?
        csv << [pdo.legal_name, pdo.id, e.inspect.to_s, pdo.owner_profile_id, pdo.sponsor_profile_id]
        logger.error "update failed for: #{pdo.id}, #{e.inspect}" unless Rails.env.test?
      end
    end
    logger.info " Total #{total} plan design organizations to be migrated" unless Rails.env.test?
    logger.info " #{success} plan design organizations updated at this point." unless Rails.env.test?
    logger.info " #{failed} plan design organizations not migrated at this point." unless Rails.env.test?
  end
end