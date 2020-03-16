Before do
  Rails.cache.clear
  DatabaseCleaner.strategy = :truncation, {:except => %w[translations]}
  DatabaseCleaner.clean
  TimeKeeper.set_date_of_record_unprotected!(Date.today)
end
