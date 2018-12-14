class ExtractRatingAreasForDc < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      say_with_time("Build rating areas linking them with county_zips") do
        [2014, 2015,2016,2017,2018,2019].each do |year|
          ::BenefitMarkets::Locations::RatingArea.create!({
                                                            active_year: year,
                                                            exchange_provided_code: 'R-DC001',
                                                            county_zip_ids: [],
                                                            covered_states: ['DC']
                                                          })
        end
      end
      # Todo Check on exchange_provided_code value
    else
      say "Skipping for non-DC site"
    end
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      ::BenefitMarkets::Locations::RatingArea.delete_all
    else
      say "Skipping for non-DC site"
    end
  end
end