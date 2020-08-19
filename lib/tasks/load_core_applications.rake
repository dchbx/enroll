# This Rake can only be used in test ENV
#Rake tasks to create core 29 faa families and applications.
# before running the below rake task, run rake seed:faa_core_families to create core families

#To run rake task: to create fixtures
# RAILS_ENV=production bundle exec rake fixture_dump:generate_applications  app_hbx_ids="faacore1:872682362813621,faacore2:g7632823218hwidy221,faacore3:6hr729jn829ndu82j"
# app_hbx_ids is the combination of existing users and person hbx_id "omi_id:hbx_id,omi_id2:hbx_id2"

#To run rake task: to load fixtures to db
# RAILS_ENV=production bundle exec rake fixture_dump:load_applications

namespace :fixture_dump do
  desc "Dump the applications and related models"
  task :generate_applications => :environment do

    app_hbx_ids = ENV["app_hbx_ids"].to_s

    hashed_hbx_ids = app_hbx_ids.split(",")
    hashed_hbx_ids = hashed_hbx_ids.map {|x| x = x.split(":"); Hash[x.first, x.last]}
    hashed_hbx_ids = hashed_hbx_ids.reduce(:merge)

    puts "started downloading" unless Rails.env.test?
    hashed_hbx_ids.keys.each do |key|

      p_rec= Person.by_hbx_id(hashed_hbx_ids[key])
      application = p_rec.first.primary_family.latest_submitted_application
      next unless application.present?

      if Rails.env.test?
        file_name = File.join(Rails.root,"spec", "test_data", "seedfiles/fixtures_dump", "application_#{key}.yaml")
      else
        file_name = File.join(Rails.root, "db", "fixtures_dump", "application_#{key}.yaml")
      end

      File.open(file_name, 'w') do |f|
        f.write application.to_yaml
      end
      print "." unless Rails.env.test?
      puts "" unless Rails.env.test?
    end
    puts "applications generated successfully" unless Rails.env.test?
  end

  task :load_applications, [:file] => :environment do |task, args|

    glob_pattern = Rails.env.test? ? args[:file] : File.join(Rails.root, "db", "fixtures_dump", "application_*.yaml")

    puts "started uploading" unless Rails.env.test?

    Dir.glob(glob_pattern).each do |f_name|

      application_class = ::FinancialAssistance::Application
      applicant_class = ::FinancialAssistance::Applicant
      income_class = ::FinancialAssistance::Income
      address_class_3_1 = ::Address
      phone_class_3_2 = ::Phone
      benefit_class = ::FinancialAssistance::Benefit
      address_class_4_1 = ::Address
      phone_class_4_2 = ::Phone
      deduction_class = ::FinancialAssistance::Deduction
      assisted_verification_class = ::VerificationType

      yaml_str = File.read(f_name)
      @app_fixture = YAML.load(yaml_str)
      oim_id = f_name.split("/")[-1].split("_")[-1].split(".")[0]
      users = User.where(oim_id: oim_id.to_s)

      next unless users.present?
      @family = users.first.person.primary_family
      @family.applications.delete_all if @family.applications.present?

      @app_fixture.assign_attributes(id: generate_bson_id_for_fixtures, family_id: @family.id, hbx_id: generate_hbx_id_for_fixtures,
                                     aasm_state: "draft", created_at: current_utc_time, updated_at: nil,
                                     submitted_at: nil, determination_http_status_code: nil)

      @count = 0
      @hashed_ids = {}

      @app_fixture.active_applicants.each do |applicant |
        get_hash applicant
      end

      @app_fixture.active_applicants.each do |applicant |
        load_app_data applicant
      end

      @hashed_ids.each do |h|
        @app_fixture.active_applicants.select {|a| a.claimed_as_tax_dependent_by == BSON::ObjectId.from_string(h[0].to_s)}.first.update_attributes(claimed_as_tax_dependent_by: h[1])
      end

      @app_fixture.new_record = true
      @app_fixture.save!
      print "." unless Rails.env.test?
      puts "" unless Rails.env.test?
    end
    puts "applications loaded successfully" unless Rails.env.test?
  end
end

def generate_hbx_id_for_fixtures
  HbxIdGenerator.generate_application_id
end

def generate_bson_id_for_fixtures
  BSON::ObjectId.new
end

def current_utc_time
  Time.now.utc
end

def basic_params
  {id: generate_bson_id_for_fixtures, created_at: current_utc_time, updated_at: nil}
end

def get_hash applicant
  if applicant.claimed_as_tax_dependent_by.present?
    @hashed_ids.merge!({"#{applicant.claimed_as_tax_dependent_by}": 0})
  end
end

def load_app_data applicant
  applicant_id = generate_bson_id_for_fixtures
  @hashed_ids[:"#{applicant.id}"] = applicant_id if @hashed_ids[:"#{applicant.id}"].present?

  applicant.assign_attributes(id: applicant_id, family_member_id: @family.family_members[@count].id,
                              created_at: current_utc_time, updated_at: nil, tax_household_id: nil)

  applicant.incomes.each do |income|
    income.assign_attributes(basic_params)

    if income.employer_address.present?
      income.employer_address.assign_attributes(basic_params)
    end

    if income.employer_phone.present?
      income.employer_phone.assign_attributes(basic_params)
    end
  end

  applicant.benefits.each do |benefit|
    benefit.assign_attributes(basic_params)

    if benefit.employer_address.present?
      benefit.employer_address.assign_attributes(basic_params)
    end

    if benefit.employer_phone.present?
      benefit.employer_phone.assign_attributes(basic_params)
    end
  end

  applicant.deductions.each do |deduction|
    deduction.assign_attributes(basic_params)
  end

  applicant.verification_types.each do |verification_type|
    verification_type.assign_attributes(basic_params)

    if verification_type.vlp_documents.present?
      verification_type.vlp_documents.each do |vlp_doc|
        vlp_doc.assign_attributes(basic_params)
      end
    end
  end

  @count = @count +1
end