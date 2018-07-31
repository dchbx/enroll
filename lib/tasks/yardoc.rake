unless Rails.env.production?
  if ENV["YARD"] == "true"
    require 'yard'

    YARD::Rake::YardocTask.new do |t|
    end

    YARD::Rake::YardocTask.new("yard:engines") do |t|
      t.files = [
        'components/benefit_markets/lib/**/*.rb',
        'components/benefit_markets/app/**/*.rb',
        'components/benefit_sponsors/lib/**/*.rb',
        'components/benefit_sponsors/app/**/*.rb'
      ]
    end
  end
end
