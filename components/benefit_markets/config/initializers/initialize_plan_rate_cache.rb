unless Rails.env.test?
  ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
end
