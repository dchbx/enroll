module Forms
  class BenefitPackage
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :title, :description, :probation_period_kind
    attr_accessor :benefit_application, :product_packages

    validates :title, presence: true

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end

    def assign_application_attributes(atts = {})
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def build(params)
      assign_application_attributes(params)
      return false unless valid?

      BenefitSponsors::BenefitPackages::BenefitPackageBuilder.build do |builder|
        builder.set_presenter_object(self)
        builder.add_title
        builder.add_description
        builder.add_probation_period_kind
        builder.add_sponsored_benefits(params[:sponsored_benefits])
      end
    end

    def get_product_packages
      benefit_catalog = benefit_application.benefit_catalog
      raise "Unable to find benefit catalog!!" if catalog.blank?
      @product_packages = benefit_catalog.product_packages
    end
  end
end
