module BenefitMarkets
  module Services
    class BenefitMarketService
      def initialize(params = {})
        @factory_class = BenefitMarkets::Factories::BenefitMarket
        @params = params
      end

      def build(attrs={})
        @factory_class.build
      end

      def store!(form)
        BenefitMarkets::Factories::BenefitMarket.call(form_attributes_to_params(form))
      end

      def form_params_to_attributes(form, benefit_market)
        configuration = case form.kind
        when 'aca_shop'
          BenefitMarkets::Factories::AcaShopConfiguration.call form.aca_shop_configuration.attributes.merge({
            initial_application_configuration: form.aca_shop_configuration.initial_application_configuration.attributes,
            renewal_application_configuration: form.aca_shop_configuration.renewal_application_configuration.attributes
          })
        when 'aca_individual'
          BenefitMarkets::Factories::AcaIndividualConfiguration.call form.aca_individual_configuration.attributes.merge({
            initial_application_configuration: form.aca_individual_configuration.initial_application_configuration.attributes
          })
        end

        model_attributes = {
          description: form.description,
          kind: form.kind,
          site_urn: form.site_urn,
          title: form.title,
          configuration: configuration
        }
        benefit_market.assign_attributes(model_attributes)
      end

      def attributes_to_form_params(benefit_market, shop_configuration, individual_configuration, form)
        form.attributes = benefit_market.attributes.merge({
          aca_individual_configuration: individual_configuration.attributes.merge({
            initial_application_configuration: individual_configuration.initial_application_configuration.attributes
          }),
          aca_shop_configuration: shop_configuration.attributes.merge({
            initial_application_configuration: shop_configuration.initial_application_configuration.attributes,
            renewal_application_configuration: shop_configuration.renewal_application_configuration.attributes
          })
        })
        form
      end

      # Load the peristance entities and use them to populate the form
      # attributes.
      #
      # Normally this method would contain only a persistence lookup and
      # attribute mappings.
      # In my case I have to figure out which form subclass I should be using.
      # @param form [Object] The form for which to load the parameters.
      # @return [Object] A form object containing the loaded parameters.
      def load_form_params_from_resource(form)
        benefit_market = find_model_by_id(form.id)
        shop_configuration, individual_configuration = if benefit_market.kind.to_s == 'aca_shop'
          [ benefit_market.configuration, ::BenefitMarkets::Factories::AcaIndividualConfiguration.build ]
        else
          [ ::BenefitMarkets::Factories::AcaShopConfiguration.build, benefit_market.configuration ]
        end

        attributes_to_form_params(benefit_market, shop_configuration, individual_configuration, form)
      end

      def find_model_by_id(id)
        BenefitMarkets::BenefitMarket.find(id)
      end

      def update(form)
        benefit_market = find_model_by_id(form.id)
        form_params_to_attributes(form, benefit_market)
        store(form, benefit_market)
      end

      def save(form)
        if form.kind == "aca_shop"
          initial_application_configuration = BenefitMarkets::Factories::AcaShopInitialApplicationConfiguration.call form.aca_shop_configuration.initial_application_configuration.attributes
          renewal_application_configuration = BenefitMarkets::Factories::AcaShopRenewalApplicationConfiguration.call form.aca_shop_configuration.renewal_application_configuration.attributes
          configuration = BenefitMarkets::Factories::AcaShopConfiguration.call form.aca_shop_configuration.attributes.merge(
              initial_application_configuration: initial_application_configuration,
              renewal_application_configuration: renewal_application_configuration
            )
        elsif form.kind == "aca_individual"
          initial_application_configuration = BenefitMarkets::Factories::AcaIndividualInitialApplicationConfiguration.call form.aca_individual_configuration.initial_application_configuration.attributes
          configuration = BenefitMarkets::Factories::AcaIndividualConfiguration.call form.aca_individual_configuration.attributes.merge(
              initial_application_configuration: initial_application_configuration
            )
        end

        benefit_market = BenefitMarkets::Factories::BenefitMarket.call description: form.description,
          site_id: form.site_id,
          kind: form.kind,
          site_urn: form.site_urn,
          title: form.title,
          configuration: configuration

        valid_according_to_factory = BenefitMarkets::Factories::BenefitMarket.validate(benefit_market)
        unless valid_according_to_factory
          map_errors_for(benefit_market, onto: form)
          return false
        end

        save_successful = benefit_market.save
        unless save_successful
          map_errors_for(benefit_market, onto: form)
          return false
        end
        true
      end

      def store(form, benefit_market)
        if benefit_market.save
          true
        else
          map_errors_for(benefit_market, onto: form)
          false
        end
      end

      def map_errors_for(benefit_market, onto:)
        case benefit_market.kind
        when :aca_shop
          benefit_market.configuration.errors.each do |att, err|
            onto.aca_shop_configuration.errors.add(att, err)
          end
          benefit_market.configuration.initial_application_configuration.errors.each do |att, err|
            onto.aca_shop_configuration.initial_application_configuration.errors.add(att, err)
          end
          benefit_market.configuration.renewal_application_configuration.errors.each do |att, err|
            onto.aca_shop_configuration.renewal_application_configuration.errors.add(att, err)
          end
        when :aca_individual
          benefit_market.configuration.errors.each do |att, err|
            onto.aca_individual_configuration.errors.add(att, err)
          end
          benefit_market.configuration.initial_application_configuration.errors.each do |att, err|
            onto.aca_individual_configuration.initial_application_configuration.errors.add(att, err)
          end
        end

        benefit_market.errors.each do |att, err|
          onto.errors.add(att, err)
        end
      end
    end
  end
end
