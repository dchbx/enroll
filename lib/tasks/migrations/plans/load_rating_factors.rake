require 'rake'

namespace :load_rating_factors do

  task :run_all_rating_factors => :environment do
    if Settings.site.key.to_s == "dc"
      Rake::Task['load_rating_factors:dc_rating_factors'].invoke
    else
      files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/rating_factors", "**", "*.xlsx"))
      puts "*"*80 unless Rails.env.test?
      files.each do |file|
        puts "processing file #{file}" unless Rails.env.test?
        #  old model
        Rake::Task['load_rating_factors:update_factor_sets'].invoke(file)
        Rake::Task['load_rating_factors:update_factor_sets'].reenable
        #  end of old model

        # new model
        Rake::Task['load_rating_factors:update_factor_sets_new_model'].invoke(file)
        Rake::Task['load_rating_factors:update_factor_sets_new_model'].reenable
        # end of new model
      end
    end
    puts "*"*80 unless Rails.env.test?
  end

  desc "DC rating factors"
  task :dc_rating_factors, [:active_year] => :environment do |t, args|
    if Settings.site.key.to_s == "dc"
      years = args[:active_year].present? ? [args[:active_year].to_i] : (2014..2021)
      years.each do |year|
        puts "creating dc rating factors for #{year}" unless Rails.env.test?
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
          # participation rate factor

          ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor.find_or_create_by!(
              active_year: year,
              default_factor_value: 1.0,
              max_integer_factor_key: 100,
              issuer_profile_id: issuer_profile.id.to_s,
              # actuarial_factor_entries: []
          )
          # group size factor
          ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor.find_or_create_by!(
              active_year: year,
              default_factor_value: 1.0,
              max_integer_factor_key: 1,
              issuer_profile_id: issuer_profile.id,
              # actuarial_factor_entries: []
          )
        end
      end
    end
  end

  task :update_factor_sets_new_model, [:file_name] => :environment do |t,args|
    ROW_DATA_BEGINS_ON ||= 3

    NEW_RATING_FACTOR_PAGES ||= {
      'SicCodeRatingFactorSet': { page: 0, max_integer_factor_key: nil },
      'EmployerGroupSizeRatingFactorSet': { page: 1, max_integer_factor_key: 50 },
      'EmployerParticipationRateRatingFactorSet': { page: 2, max_integer_factor_key: nil },
      'CompositeRatingTierFactorSet': { page: 3, max_integer_factor_key: nil }
    }
    RATING_FACTOR_DEFAULT ||= 1.0

    COMPOSITE_TIER_TRANSLATIONS ||= {
      'Employee': 'employee_only',
      'Employee + Spouse': 'employee_and_spouse',
      'Employee + Dependent(s)': 'employee_and_one_or_more_dependents',
      'Family': 'family'
    }.with_indifferent_access

    begin
      @issuer_profile_hash = {}
      set_issuer_profile_hash
      @file_path = args[:file_name]
      @year = @file_path.split("/")[-2].to_i
      xlsx = Roo::Spreadsheet.open(@file_path)
      NEW_RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_info|
        sheet = xlsx.sheet(sheet_info[:page])
        max_integer_factor_key = sheet_info[:max_integer_factor_key]

        (2..number_of_carriers + 1).each do |carrier_column|
          issuer_hios_id = sheet.cell(2,carrier_column).to_i.to_s
          issuer_profile_id = @issuer_profile_hash[issuer_hios_id]
          if issuer_profile_id.present?

            obj = case(Object.const_get(rating_factor_class))
            when(SicCodeRatingFactorSet)
              ::BenefitMarkets::Products::ActuarialFactors::SicActuarialFactor
            when(EmployerGroupSizeRatingFactorSet)
              ::BenefitMarkets::Products::ActuarialFactors::GroupSizeActuarialFactor
            when(EmployerParticipationRateRatingFactorSet)
              ::BenefitMarkets::Products::ActuarialFactors::ParticipationRateActuarialFactor
            when(CompositeRatingTierFactorSet)
              ::BenefitMarkets::Products::ActuarialFactors::CompositeRatingTierActuarialFactor
            end

            existing_record = obj.where(
              active_year: @year,
              default_factor_value: RATING_FACTOR_DEFAULT,
              issuer_profile_id: issuer_profile_id,
              max_integer_factor_key: max_integer_factor_key
            )
            next if existing_record.count > 0

            obj.new(
              active_year: @year,
              default_factor_value: RATING_FACTOR_DEFAULT,
              issuer_profile_id: issuer_profile_id,
              max_integer_factor_key: max_integer_factor_key
            ).tap do |factor_set|
              (ROW_DATA_BEGINS_ON..sheet.last_row).each do |i|
                factor_key = sheet.cell(i,1)
                if is_composite_rating_tier?(rating_factor_class)
                  factor_key = COMPOSITE_TIER_TRANSLATIONS[factor_key.to_s]
                end

                if is_group_size_rating_tier?(rating_factor_class)
                  factor_key = factor_key.to_i
                end

                if is_participation_rate_rating_tier?(rating_factor_class)
                  factor_key = (factor_key * 100).to_i
                end

                factor_value = sheet.cell(i,carrier_column) || 1.0
                factor_set.actuarial_factor_entries.new(
                                                      factor_key: factor_key,
                                                      factor_value: factor_value
                                                    )
              end  ## finished the sheet
              factor_set.save!
            end
          end
        end
      end
    rescue => e
      puts e.inspect
    end

  end

  desc "load rating factors from xlsx file"
  task :update_factor_sets, [:file_name] => :environment do |t,args|
    CURRENT_ACTIVE_YEAR ||= TimeKeeper.date_of_record.year
    ROW_DATA_BEGINS_ON ||= 3
    RATING_FACTOR_PAGES ||= {
      'SicCodeRatingFactorSet': { page: 0, max_integer_factor_key: nil },
      'EmployerGroupSizeRatingFactorSet': { page: 1, max_integer_factor_key: 50 },
      'EmployerParticipationRateRatingFactorSet': { page: 2, max_integer_factor_key: nil },
      'CompositeRatingTierFactorSet': { page: 3, max_integer_factor_key: nil }
    }
    RATING_FACTOR_DEFAULT ||= 1.0

    COMPOSITE_TIER_TRANSLATIONS ||= {
      'Employee': 'employee_only',
      'Employee + Spouse': 'employee_and_spouse',
      'Employee + Dependent(s)': 'employee_and_one_or_more_dependents',
      'Family': 'family'
    }.with_indifferent_access

    begin
        @file_path = args[:file_name]
        @year = @file_path.split("/")[-2].to_i
        xlsx = Roo::Spreadsheet.open(@file_path)
        RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_info|
          rating_factor_set = Object.const_get(rating_factor_class)
          ## WARNING THIS DESTROYS ALL CURRENT YEAR FACTOR SETS
          rating_factor_set.where(active_year: @year).destroy_all if Rails.env.test?
          sheet = xlsx.sheet(sheet_info[:page])
          max_integer_factor_key = sheet_info[:max_integer_factor_key]
          (2..number_of_carriers + 1).each do |carrier_column|
            issuer_hios_id = sheet.cell(2,carrier_column).to_i.to_s

            ## Need to Import Carriers First to associate with CarrierProfile
            begin
              organization = Organization.where("carrier_profile.issuer_hios_ids" => issuer_hios_id).first

              if organization.present?
                carrier_profile = organization.carrier_profile


                existing_record = rating_factor_set.where(
                  active_year: @year,
                  carrier_profile_id: carrier_profile.id.to_s,
                  default_factor_value: RATING_FACTOR_DEFAULT,
                  max_integer_factor_key: max_integer_factor_key
                )
                next if existing_record.count > 0

                rating_factor_set.new(active_year: @year,
                  carrier_profile: carrier_profile,
                  default_factor_value: RATING_FACTOR_DEFAULT,
                  max_integer_factor_key: max_integer_factor_key
                ).tap do |factor_set|  ## initialized factor set, now iterate through the column
                  (ROW_DATA_BEGINS_ON..sheet.last_row).each do |i|
                    factor_key = sheet.cell(i,1)
                    if is_composite_rating_tier?(rating_factor_class)
                      factor_key = COMPOSITE_TIER_TRANSLATIONS[factor_key.to_s]
                    end
                    factor_value = sheet.cell(i,carrier_column) || 1.0

                    if is_group_size_rating_tier?(rating_factor_class)
                      factor_key = factor_key.to_i
                    end

                    if is_participation_rate_rating_tier?(rating_factor_class)
                      factor_key = (factor_key * 100).to_i
                    end

                    factor_set.rating_factor_entries.new(
                                                          factor_key: factor_key,
                                                          factor_value: factor_value
                                                        )
                  end  ## finished the sheet
                  factor_set.save!
                end
              end
            rescue Mongoid::Errors::DocumentNotFound
              puts "Error: There was no matching Carrier Profile for this column"
              puts "Import Carrier Profiles before running this script"
            end
          # end
        end
      end

    rescue => e
      puts e.inspect
    end
  end

  def set_issuer_profile_hash
    exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    exempt_organizations.each do |exempt_organization|
      issuer_profile = exempt_organization.issuer_profile
      issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
        @issuer_profile_hash[issuer_hios_id] = issuer_profile.id.to_s
      end
    end
    @issuer_profile_hash
  end

  def number_of_carriers
    case(@year)
    when 2017
      return 12
    when 2018
      return 12
    when 2019
      return 12
    end
  end

  def is_group_size_rating_tier?(rating_factor_class)
    'EmployerGroupSizeRatingFactorSet'.eql? rating_factor_class.to_s
  end

  def is_composite_rating_tier?(rating_factor_class)
    'CompositeRatingTierFactorSet'.eql? rating_factor_class.to_s
  end

  def is_participation_rate_rating_tier?(rating_factor_class)
    'EmployerParticipationRateRatingFactorSet'.eql? rating_factor_class.to_s
  end
end
