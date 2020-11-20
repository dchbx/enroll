namespace :shop do
  desc "Load issuer profiles, service areas, rating areas data"
  task :issuer_and_locations_seed => :environment do

    puts "::: Creating Issuer profiles, service areas, rating areas ::::"

    current_year = TimeKeeper.date_of_record.year
    years = [current_year - 1, current_year, current_year + 1]

    # Create Issuer Profiles

    file = File.open("db/seedfiles/issuer_profiles.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)

    JSON.parse(data).each do |organization_params|
      organization_params.deep_symbolize_keys!
      issuer = BenefitSponsors::Organizations::ExemptOrganization.new(organization_params.except(:profiles))
      issuer.profiles = organization_params[:profiles].inject([]) do |result, profile_hash|
        result << BenefitSponsors::Organizations::IssuerProfile.new(profile_hash)
        result
      end
      issuer.save!
    end

    # - Service Areas
    years.each do |year|
      system "bundle exec rake load_service_reference:dc_service_areas[#{year}]"
    end

    # - Rating Areas

    years.each do |year|
      system "bundle exec rake load_rate_reference:dc_rating_areas[#{year}]"
    end
    puts "::: Created Issuer profiles, service areas, rating areas ::::"
  end
end


RSpec.describe "products seed", dbclean: :after_each do
  require 'rake'

  before :context do
    Rake::Task.define_task(:environment)
    Rake::Task['shop:issuer_and_locations_seed'].invoke
  end

  context 'building issuer profiles' do
    it "should create 9 issuer profiles, service areas and rating areas" do
      expect(BenefitSponsors::Organizations::ExemptOrganization.issuer_profiles.size).to eq 9
      expect(::BenefitMarkets::Locations::ServiceArea.all.size).not_to eq 0
      expect(::BenefitMarkets::Locations::RatingArea.all.size).not_to eq 0
    end
  end
end
