FactoryGirl.define do
  factory :sponsored_benefits_rating_models_rating_factor, class: 'SponsoredBenefits::RatingModels::RatingFactor' do
    
    rating_model_key :healh_composite_rating_factor 
    key :group_participation_ratio
    value 1.0

  end
end
