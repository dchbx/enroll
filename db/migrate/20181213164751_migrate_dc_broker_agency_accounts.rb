# frozen_string_literal: true

class MigrateDcBrokerAgencyAccounts < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      @logger = Logger.new("#{Rails.root}/log/cca_baa_migration.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      migrate_broker_agency_accounts

      @logger.info "End of the script- #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down; end

  private

  def self.migrate_broker_agency_accounts
    say_with_time("Time taken to create broker agency profile hash") do
      @broker_hash = {}
      Organization.where(:broker_agency_profile.exists => true).each do |org|

        new_broker_agency_profile = new_broker_agency_for_old_profile_id(org.broker_agency_profile.id)
        raise "new broker agency profile not found #{org.hbx_id}" unless new_broker_agency_profile.present?
        @broker_hash[org.broker_agency_profile.id] = new_broker_agency_profile.id
      rescue Exception => e
        print 'F' unless Rails.env.test?
        @logger.error "Failed to create broker hash: #{org.id}, #{e.inspect}" unless Rails.env.test?

      end
    end

    say_with_time("Time taken to migrate shop broker agency accounts") do
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:broker_agency_accounts.exists => true).each do |benefit_sponsorship|

        benefit_sponsorship.broker_agency_accounts.unscoped.each do |account|
          new_profile_id = @broker_hash[account.as_document["broker_agency_profile_id"]]
          puts "Mapping not found for broker agency profile, sponsorship_id: #{benefit_sponsorship.id}" if new_profile_id.blank?

          account._id = BSON::ObjectId.new
          account.benefit_sponsors_broker_agency_profile_id = new_profile_id

          BenefitSponsors::Accounts::BrokerAgencyAccount.skip_callback(:save, :after, :notify_on_save, raise: false)
          BenefitSponsors::Accounts::BrokerAgencyAccount.skip_callback(:create, :before, :notify_observers, raise: false)
          BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save, raise: false)

          account.save
          print '.' unless Rails.env.test?
        end
      rescue Exception => e
        print 'F' unless Rails.env.test?
        @logger.error "Broker Accounts Migration Failed For Shop: #{benefit_sponsorship.id}, #{e.inspect}" unless Rails.env.test?

      end
    end

    say_with_time("Time taken to migrate family broker agency accounts") do
      Family.where(:broker_agency_accounts.exists => true).each do |fam|

        fam.broker_agency_accounts.unscoped.each do |account|

          new_profile_id = @broker_hash[account.as_document["broker_agency_profile_id"]]
          puts "Mapping not found for broker agency profile, family_id: #{fam.id}" if new_profile_id.blank?

          account.benefit_sponsors_broker_agency_profile_id = @broker_hash[account.as_document["broker_agency_profile_id"]]

          BenefitSponsors::Accounts::BrokerAgencyAccount.skip_callback(:save, :after, :notify_on_save, raise: false)
          BenefitSponsors::Accounts::BrokerAgencyAccount.skip_callback(:create, :before, :notify_observers, raise: false)
          account.save
          print '.' unless Rails.env.test?
        end
      rescue Exception => e
        print 'F' unless Rails.env.test?
        @logger.error "Broker Accounts Migration Failed For Family: #{fam.id}, #{e.inspect}" unless Rails.env.test?

      end
    end
    reset_hash
    BenefitSponsors::Accounts::BrokerAgencyAccount.set_callback(:create, :before, :notify_observers, raise: false)
    BenefitSponsors::Accounts::BrokerAgencyAccount.set_callback(:save, :after, :notify_observers, raise: false)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.set_callback(:save, :after, :notify_on_save, raise: false)
  end

  def self.reset_hash
    @broker_hash = {}
  end

  def self.new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id).first
  end

  def self.old_broker_agency_profile(id)
    Rails.cache.fetch("broker_agency_profile_#{id}", expires_in: 2.hour) do
      ::BrokerAgencyProfile.find(id)
    end
  end

  def self.new_broker_agency_for_old_profile_id(id)
    Rails.cache.fetch("new_broker_agency_#{id}", expires_in: 2.hour) do
      old_org = old_broker_agency_profile(id)
      BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id).first.broker_agency_profile
    end
  end
end