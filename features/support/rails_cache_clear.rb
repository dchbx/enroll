Before do
  Rails.cache.clear
  DatabaseCleaner.strategy = :truncation, {:except => %w[translations]}
  DatabaseCleaner.clean
end