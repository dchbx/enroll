# frozen_string_literal: true

::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache! unless Rails.env.test?
