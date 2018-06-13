unless Rails.env.production?
  YARD::Rake::YardocTask.new do |t|
  end

  YARD::Rake::YardocTask.new("yard:engines") do |t|
    t.files = [
      'components/*/lib/**/*.rb',
      'components/*/app/**/*.rb'
    ]
  end
end
