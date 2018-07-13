class CcaBrokerAgencyAccountsMigration < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/cca_baa_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( hbx_id legal_name old_bk_agency_accs benefit_sponsor_organization_id
                        total_benefit_sponsorships accounts_in_each_benefit_sponsorship migrated_bk_agency_accs status valid_account)

      logger = Logger.new("#{Rails.root}/log/cca_baa_migration.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        migrate_accounts(csv, logger)

        puts "" unless Rails.env.test?
        puts "Check cca_baa_migration logs & cca_baa_migration_status csv for additional information." unless Rails.env.test?
      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.migrate_accounts(csv, logger)

    @new_organizations = BenefitSponsors::Organizations::Organization

    migrated_organizations = @new_organizations.employer_profiles
    limit_count = 1000

    @total_bk_accounts = 0
    count = 0

    migrated_organizations.batch_size(limit_count).no_timeout.each do |organization|

      old_org = Organization.all_employer_profiles.where(fein: organization.fein)
      next unless old_org.present?

      old_ep = old_org.first.employer_profile
      old_bk_agency_accs = find_broker_agency_accounts(old_ep)
      next unless old_bk_agency_accs.present?
      total_bk_agency_accs = old_bk_agency_accs.count

      benefit_sponsorships = organization.benefit_sponsorships.unscoped
      next unless benefit_sponsorships.present?

      new_baa = benefit_sponsorships.exists(broker_agency_accounts: true)

      unless new_baa.count == 0
        csv << [old_org.first.hbx_id, old_org.first.legal_name, total_bk_agency_accs, organization.id, new_baa.count, "Already Migrated", "-", "-", "-"]
        next
      end

      count += total_bk_agency_accs

      begin

        if benefit_sponsorships.count == 1
          # This is used when there is only one benefit sponsorship
          old_bk_agency_accs.each do |old_bk_agency_acc|
            benefit_sponsorship = benefit_sponsorships.first
            find_and_create(old_bk_agency_acc, benefit_sponsorship, csv)
          end

        elsif benefit_sponsorships.count > 1
          # This is used when there is more than one benefit sponsorship
          active_bk_accs = find_active_broker_agency_accounts(old_ep)
          inactive_bk_accs = find_inactive_broker_agency_accounts(old_ep)

          if active_bk_accs.present?
            #all active broker agency accounts use this block
            old_active_bk_acc = active_bk_accs.first
            latest_bs= organization.latest_benefit_sponsorship
            find_and_create(old_active_bk_acc, latest_bs, csv)
          end

          bss_with_date = benefit_sponsorships.where(effective_begin_on: {'$ne' => nil})

          #all inactive broker agency accounts use this block
          inactive_bk_accs.order_by(:'start_on'.desc).group_by {|item| item.start_on.to_date}.select {|k, v| v.size > 0}.each_pair do |hire_on, bk_agency_accs|

            benefit_sponsorships_for_accs = bss_with_date.where(:'effective_begin_on'.lte => hire_on).and(:'effective_end_on'.gte => hire_on)

            if benefit_sponsorships_for_accs.count > 0
              # pick benefitsponsorship , hire date of broker should be between effective begin on and effective end on
              bs = benefit_sponsorships_for_accs.order_by(:'effective_begin_on'.desc).first
            elsif bss_with_date.where(:'effective_begin_on'.lte => hire_on).count
              bs = bss_with_date.where(:'effective_begin_on'.lte => hire_on).order_by(:'effective_begin_on'.desc).first
            else
              #this is default , if non of the benefitsponsorship fits, this block is used
              bs = organization.latest_benefit_sponsorship
            end

            next unless bs.present?

            bk_agency_accs.each do |bk_agency_acc|
              find_and_create(bk_agency_acc, bs, csv)
            end
          end
        end

        organization.save!
        total_bss = organization.benefit_sponsorships.unscoped
        total_benefit_sponsorships = total_bss.count
        arrayed = total_bss.unscoped.map {|benefit_sponsorship| benefit_sponsorship.broker_agency_accounts.unscoped.count}
        total_migrated_bk_agency_accs = arrayed.reduce(0, :+)
        print '.' unless Rails.env.test?
        csv << [old_org.first.hbx_id, old_org.first.legal_name, total_bk_agency_accs, organization.id, total_benefit_sponsorships, arrayed, total_migrated_bk_agency_accs, (total_bk_agency_accs == total_migrated_bk_agency_accs), "-"]
      rescue Exception => e
        logger.error "Broker Accounts Migration Failed for old Organization HBX_ID: #{old_org.first.hbx_id},
          #{e.inspect}" unless Rails.env.test?
      end
    end
    logger.info " Total #{count} accounts to be migrated" unless Rails.env.test?
    logger.info " Total #{@total_bk_accounts} accounts migrated" unless Rails.env.test?
  end

  def self.find_and_create(old_broker_agency_account, benefit_sponsorship, csv)
    old_bk_org = Organization.has_broker_agency_profile.where(:"broker_agency_profile._id" => BSON::ObjectId(old_broker_agency_account.broker_agency_profile_id))
    new_bk_org = @new_organizations.where(hbx_id: old_bk_org.first.hbx_id)
    create_broker_agency_account(new_bk_org, old_broker_agency_account, benefit_sponsorship, csv)
  end

  def self.find_broker_agency_accounts(old_ep)
    old_ep.broker_agency_accounts.unscoped
  end

  def self.find_active_broker_agency_accounts(old_ep)
    old_ep.broker_agency_accounts.unscoped.where(is_active: true)
  end

  def self.find_inactive_broker_agency_accounts(old_ep)
    old_ep.broker_agency_accounts.unscoped.where(is_active: false)
  end

  def self.create_broker_agency_account(new_bk_org, old_broker_agency_account, benefit_sponsorship, csv)
    json_data = old_broker_agency_account.to_json(:except => [:_id, :broker_agency_profile_id, :writing_agent_id])
    broker_agency_account_params = JSON.parse(json_data)
    broker_agency_profile_id = new_bk_org.first.broker_agency_profile.id
    person = Person.where(:"broker_role.benefit_sponsors_broker_agency_profile_id" => broker_agency_profile_id)
    broker_role_id = person.first.broker_role.id if person.present?

    #creating broker_agency account in new model
    new_broker_agency_account = benefit_sponsorship.broker_agency_accounts.new(broker_agency_account_params)

    if old_broker_agency_account.writing_agent_id.present? && broker_role_id.present?
      new_broker_agency_account.writing_agent_id = broker_role_id
    else
      status = "no broker role present for this profile"
      csv << [new_bk_org.first.hbx_id, new_bk_org.first.legal_name, "This is broker profile", "-", "-", "-", "-", "-", status]
    end

    new_broker_agency_account.benefit_sponsors_broker_agency_profile_id = broker_agency_profile_id
    BenefitSponsors::Accounts::BrokerAgencyAccount.skip_callback(:save, :after, :notify_on_save)
    new_broker_agency_account.save!
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save)
    benefit_sponsorship.save!
    @total_bk_accounts += 1
  end
end