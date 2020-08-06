# frozen_string_literal: true

class MigrateDcBrokerQuotingTool < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      @logger = Logger.new("#{Rails.root}/log/plan_design_migration_data.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      update_plan_design_organization

      puts "" unless Rails.env.test?
      puts "Check plan_design_migration_data logs & plan_design_migration_status csv for additional information." unless Rails.env.test?

      @logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down; end

  def self.update_plan_design_organization
    say_with_time("Time taken to build data hash") do
      @plan_design_hash = {employer: {}, broker_agency: {}, general_agency: {} }

      Organization.all.each do |org|
        next if org.carrier_profile.present? || org.hbx_profile.present?
        new_org = find_org(org)
        next puts "Organization not found #{org.hbx_id}" unless new_org.present?
        @plan_design_hash[:employer].merge!({org.employer_profile.id => new_org.employer_profile.id}) if org.employer_profile.present?
        @plan_design_hash[:broker_agency].merge!({org.broker_agency_profile.id => new_org.broker_agency_profile.id}) if org.broker_agency_profile.present?
        @plan_design_hash[:general_agency].merge!({org.general_agency_profile.id => new_org.general_agency_profile.id}) if  org.general_agency_profile.present?
      end
    end

    say_with_time("Time taken to build data hash") do
      success = 0
      failed = 0

      employer = @plan_design_hash[:employer]
      broker_agency =  @plan_design_hash[:broker_agency]
      general_agency = @plan_design_hash[:general_agency]

      SponsoredBenefits::Organizations::PlanDesignOrganization.batch_size(1000).no_timeout.each do |pdo|

          # TODO: check raise, commenting for now to migrate data.
          # raise "owner profile not found" if pdo.owner_profile_id.blank?

        new_owner_profile_id = broker_agency[pdo.owner_profile_id]
        new_sponsor_profile_id = employer[pdo.sponsor_profile_id]

        # TODO: fix raise
        # raise "mapping not found for owner profile #{pdo.id}, profile_id: #{pdo.owner_profile_id}" if new_owner_profile_id.blank?
        # raise "mapping not found for sponsor profile  #{pdo.id}, profile_id: #{pdo.sponsor_profile_id}" if employer[pdo.sponsor_profile_id].present? && new_owner_profile_id.blank?

        pdo.past_owner_profile_id = pdo.owner_profile_id
        pdo.past_owner_profile_class_name = "::BrokerAgencyProfile"
        pdo.past_sponsor_profile_id = pdo.sponsor_profile_id
        pdo.past_sponsor_profile_class_name = "::EmployerProfile"

        pdo.owner_profile_id = new_owner_profile_id
        pdo.owner_profile_class_name = "::BenefitSponsors::Organizations::Profile"
        pdo.sponsor_profile_id = new_sponsor_profile_id
        pdo.sponsor_profile_class_name = "::BenefitSponsors::Organizations::Profile"

        pdo.general_agency_accounts.unscoped.each do |account|

          puts "old general agency profile not found for account" unless account.general_agency_profile_id.present?
          puts "old broker agency profile not found for account" unless account.broker_agency_profile_id.present?

          new_general_agency = general_agency[account.general_agency_profile_id]
          new_broker_agency =  broker_agency[account.broker_agency_profile_id]

          puts "mapping not found for account #{account.id}, old general agency: #{account.general_agency_profile_id}" if new_general_agency.blank?
          puts "mapping not found for account #{account.id}, old broker agency: #{account.broker_agency_profile_id}," if new_broker_agency.blank?

          account.update_attributes!(benefit_sponsrship_general_agency_profile_id: new_general_agency,
                                     benefit_sponsrship_broker_agency_profile_id: new_broker_agency)
        end

        if pdo.valid?
          pdo.save!
        else
          pdo.save!(validate: false) # TODO: verify this
          puts "plan design orgnaization not valid #{pdo.id}"
          end

        success += 1
        print '.' unless Rails.env.test?
      rescue Exception => e
        failed += 1
        print 'F' unless Rails.env.test?
        @logger.error "update failed for: #{pdo.id}, #{e.inspect}" unless Rails.env.test?

      end
      @logger.info " Total #{SponsoredBenefits::Organizations::PlanDesignOrganization.all.count} plan design organizations to be migrated" unless Rails.env.test?
      @logger.info " #{success} plan design organizations updated at this point." unless Rails.env.test?
      @logger.info " #{failed} plan design organizations not migrated at this point." unless Rails.env.test?
    end
    reset_hash
  end

  def self.find_org(org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: org.hbx_id).first
  end

  def self.reset_hash
    @plan_design_hash = {employer: {}, broker_agency: {}, general_agency: {} }
  end
end