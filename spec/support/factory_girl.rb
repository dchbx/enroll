RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  # Acheived by adding Initializer in engine
  # FactoryGirl.definition_file_paths = [
  #   File.expand_path('../../../components/benefit_markets/spec/factories', __FILE__),
  #   File.expand_path('../../../components/benefit_sponsors/spec/factories', __FILE__),
  # ]
  # FactoryGirl.find_definitions

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      # FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end

end
