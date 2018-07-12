unless Rails.env.test?
  ::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
end
