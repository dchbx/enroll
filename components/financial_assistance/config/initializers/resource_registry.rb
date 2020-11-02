# require FinancialAssistance::Engine.root.join('app', 'domain', 'types.rb')

FinancialAssistanceRegistry = ResourceRegistry::Registry.new

FinancialAssistanceRegistry.configure do |config|
  config.name       = :financial_assistance
  config.created_at = DateTime.now
  config.load_path  = FinancialAssistance::Engine.root.join('system', 'features').to_s
end