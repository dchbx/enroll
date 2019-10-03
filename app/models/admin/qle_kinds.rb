module Admin
  module QleKinds
    class QleKindsContainer
      extend Dry::Container::Mixin
      
      # Create
      register "create_params_validator" do
        ::QleKinds::CreateParamsValidator.new
      end

      register "create_domain_validator" do
        ::QleKinds::CreateDomainValidator.new
      end

      register "create_virtual_model" do
        Admin::QleKinds::CreateRequest
      end
      
      # Deactivate
      register "deactivate_params_validator" do
        ::QleKinds::DeactivateParamsValidator.new
      end

      register "deactivate_domain_validator" do
        ::QleKinds::DeactivateDomainValidator.new
      end

      register "deactivate_virtual_model" do
        Admin::QleKinds::DeactivateRequest
      end
      
      # Update
      register "update_params_validator" do
        ::QleKinds::UpdateParamsValidator.new
      end

      register "update_domain_validator" do
        ::QleKinds::UpdateDomainValidator.new
      end

      register "update_virtual_model" do
        Admin::QleKinds::UpdateRequest
      end
    end

    Injection = Dry::AutoInject(QleKindsContainer)
  end
end