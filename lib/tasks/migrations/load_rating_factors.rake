require 'rake'

namespace :load_rating_factors do

  task :run_all_rating_factors => :environment do
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/rating_factors", "**", "*.xlsx"))
    puts "*"*80 unless Rails.env.test?
    files.each do |file|
      puts "processing file #{file}" unless Rails.env.test?
      Rake::Task['load_rating_factors:update_factor_sets'].invoke(file)
      Rake::Task['load_rating_factors:update_factor_sets'].reenable
    end
    puts "*"*80 unless Rails.env.test?
  end

  desc "load rating factors from xlsx file"
  task :update_factor_sets, [:file_name] => :environment do |t,args|
    CURRENT_ACTIVE_YEAR ||= TimeKeeper.date_of_record.year
    NUMBER_OF_CARRIERS ||= 4
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
          rating_factor_set.where(active_year: @year).destroy_all
          sheet = xlsx.sheet(sheet_info[:page])
          max_integer_factor_key = sheet_info[:max_integer_factor_key]
          (2..number_of_carriers + 1).each do |carrier_column|
            issuer_hios_id = sheet.cell(2,carrier_column).to_i.to_s

            ## Need to Import Carriers First to associate with CarrierProfile
            begin
              organization = Organization.where("carrier_profile.issuer_hios_ids" => issuer_hios_id).first

              if organization.present?
                carrier_profile = organization.carrier_profile
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

  def number_of_carriers
    case(@year)
    when 2017
      return 8
    when 2018
      return 9
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
