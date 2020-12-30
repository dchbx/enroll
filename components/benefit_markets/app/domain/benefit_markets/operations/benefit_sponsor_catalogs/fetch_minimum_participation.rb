module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs

      class FetchMinimumParticipation

        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Products::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(product_package:,  calender_year:)
          minimum_participation  = yield fetch(product_package, calender_year)
    
          Success(minimum_participation)
        end

        private

        def fetch(product_package, calender_year)
          if contribution_key = product_package&.contribution_model&.key
            minimum_participation = ::EnrollRegistry["#{product_package.benefit_kind}_fetch_enrollment_minimum_participation_#{calender_year}"].setting(product_package.contribution_model.key)&.item
            if minimum_participation.present?
              Success(minimum_participation)
            else
              Failure("unable to find minimum contribution for given contribution model.")
            end
          else
            Failure("contribution key missing.")
          end
        end
      end
    end
  end
end