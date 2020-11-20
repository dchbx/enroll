namespace :shop do
  desc "Load products data"
  task :products_seed => :environment do

    current_year = TimeKeeper.date_of_record.year
    years = [current_year - 1, current_year, current_year + 1]

    file = File.open("db/seedfiles/products.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)

    issuer_hash = BenefitSponsors::Organizations::ExemptOrganization.issuer_profiles.inject({}) do |result, organization|
      hios_ids = organization.issuer_profile.issuer_hios_ids
      hios_ids.each do |hios_id|
        result[hios_id] = organization.issuer_profile.id.to_s
      end
      result
    end
    years.each do |year|
      start_date = Date.new(year, 1, 1)
      end_date = start_date.end_of_year
      service_areas = BenefitMarkets::Locations::ServiceArea.where(active_year: year)
      rating_area_id = ::BenefitMarkets::Locations::RatingArea.where(active_year: year).first.id.to_s
      puts ":::: Creating  products for #{year} benefit year ::::" unless Rails.env.test?
      data.each do |product_hash|
        product_hash = JSON.parse(product_hash).deep_symbolize_keys!
        product_hash[:application_period] = {min: start_date, max: end_date}
        product_hash[:issuer_profile_id] = issuer_hash[product_hash[:hios_id].first(5)]
        product_hash[:service_area_id] = service_areas.where(issuer_profile_id: product_hash[:issuer_profile_id]).first&.id&.to_s
        product_hash[:premium_tables].each do |pt|
          pt[:rating_area_id] = rating_area_id
        end
        product_hash[:kind].to_s == 'health' ? BenefitMarkets::Products::HealthProducts::HealthProduct.create(product_hash) :BenefitMarkets::Products::DentalProducts::DentalProduct.create(product_hash)
      end
      puts ":::: Created #{data.length} products for #{year} benefit year ::::" unless Rails.env.test?
    end
  end
end

RSpec.describe "products seed", dbclean: :after_each do
  require 'rake'

  before :context do
    Rake::Task.define_task(:environment)
    Rake::Task['shop:products_seed'].invoke
  end

  context 'building products' do
    it "should create products for current year, next year and previous year" do
      expect(BenefitMarkets::Products::Product.where(:'application_period.min' => Date.new(TimeKeeper.date_of_record.year, 1, 1))).not_to eq 0
      expect(BenefitMarkets::Products::Product.where(:'application_period.min' => Date.new(TimeKeeper.date_of_record.year + 1, 1, 1))).not_to eq 0
      expect(BenefitMarkets::Products::Product.where(:'application_period.min' => Date.new(TimeKeeper.date_of_record.year - 1, 1, 1))).not_to eq 0
    end
  end
end
