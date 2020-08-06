# frozen_string_literal: true

::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache! unless Rails.env.test?
