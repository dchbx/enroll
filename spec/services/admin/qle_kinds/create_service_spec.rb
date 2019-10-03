require "rails_helper"

describe Admin::QleKinds::CreateService, "given:
- a create_params_validator
- a create_domain_validator
- a create_virtual_model
" do

  let(:create_params_validator) do
    instance_double(::QleKinds::CreateParamsValidator)
  end
  let(:create_domain_validator) do 
    instance_double(::QleKinds::CreateDomainValidator)
  end
  let(:create_virtual_model) { double }
  
  let(:subject) do
     Admin::QleKinds::CreateService.new(
       create_params_validator: create_params_validator,
       create_domain_validator: create_domain_validator,
       create_virtual_model: create_virtual_model
     )
  end

  it "assigns the params validator" do
    expect(subject.create_params_validator).to eq create_params_validator
  end

  it "assigns the domain validator" do
    expect(subject.create_domain_validator).to eq create_domain_validator
  end

  it "assigns the virtual_model" do
    expect(subject.create_virtual_model).to eq create_virtual_model
  end
end

describe Admin::QleKinds::CreateService, "#call" do
  let(:create_params_validator) do
    instance_double(::QleKinds::CreateParamsValidator)
  end
  let(:create_domain_validator) do 
    instance_double(::QleKinds::CreateDomainValidator)
  end
  let(:create_virtual_model) { double }
  
  let(:subject) do
     Admin::QleKinds::CreateService.new(
       create_params_validator: create_params_validator,
       create_domain_validator: create_domain_validator,
       create_virtual_model: create_virtual_model
     )
  end

  let(:user) { double }
  let(:params) { double }
  let(:params_output) { double }

  before do
    allow(create_params_validator).to receive(
        :call
      ).with(
        params
      ).and_return(
        params_validation_result
      )
  end

  describe "given:
    - a user
    - invalid params" do
    let(:params_validation_result) { double(success?: false) }
    let(:result) { subject.call(user, params) }

    it "returns a failed result" do
      expect(result.success?).to be_falsey
    end
  end

  describe "given:
    - a user
    - valid params
    - domain invalid input
    " do
    let(:params_validation_result) do
      double(
       success?: true,
       output: params_output
      )
    end
    let(:domain_validation_result) do
      double(
       success?: false
      )
    end
    let(:virtual_model) { double }
    let(:result) { subject.call(user, params) }
    let(:existing_qle_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let(:title) {existing_qle_kind.title}
    let(:reason) {"bad reason"}

    before do
      allow(create_virtual_model).to receive(
          :new
        ).with(
          params_output
        ).and_return(
          virtual_model
        )
      allow(create_domain_validator).to receive(
          :call
        ).with(
          user: user,
          request: virtual_model,
          service: subject
        ).and_return(
          domain_validation_result
        )
    end

    it "returns a failed result" do
      expect(result.success?).to be_falsey
    end

    it '#title_is_unique' do 
      expect(subject.title_is_unique?(title)).to eq(false)
      expect(result.success?).to be_falsey
    end

    it '#reason_is_valid?' do 
      expect(subject.reason_is_valid?(reason)).to eq(true)
      expect(result.success?).to be_falsey
    end
  end

  describe "given:
    - a user
    - valid params
    - domain valid input
    " do
    let(:params_validation_result) do
      double(
       success?: true,
       output: params_output
      )
    end
    let(:domain_validation_result) do
      double(
       success?: true
      )
    end
    let(:virtual_model) do
      instance_double(
        Admin::QleKinds::CreateRequest,
        create_record_params
      )
    end
    let(:new_qle_kind_record) { double }
    let(:create_record_params) do
      {
        title: title,
        market_kind: market_kind,
        is_self_attested: is_self_attested,
        effective_on_kinds:['date_of_event'],
        pre_event_sep_in_days: 10,
        post_event_sep_in_days:10,
        tool_tip:"tool tip",
        reason:"reason",
        action_kind:"action kind",
        is_active: false,
        end_on: "11/11/1111",
        start_on: '11/11/1111'
      }
    end

    
    let(:title) { "QLE Kind Title" }
    let(:market_kind) { "QLE Kind Market Kind" }
    let(:is_self_attested) { "QLE Kind Market Kind" }
    
    before do
      allow(create_virtual_model).to receive(
        :new
      ).with(
        params_output
      ).and_return(
        virtual_model
      )
      allow(create_domain_validator).to receive(
        :call
      ).with(
        user: user,
        request: virtual_model,
        service: subject
      ).and_return(
        domain_validation_result
      )
      allow(QualifyingLifeEventKind).to receive(
        :create!
      ).with(
        create_record_params
      ).and_return(
        new_qle_kind_record
      )
    end

    it "is a success" do
      result = subject.call(user, params)
      expect(result.success?).to be_truthy
    end

    it "creates the record" do
      expect(QualifyingLifeEventKind).to receive(
        :create!
      ).with(
        create_record_params
      ).and_return(
        new_qle_kind_record
      )
      result = subject.call(user, params)
    end

    it "returns the new record" do
      result = subject.call(user, params)
      expect(result.output).to eq new_qle_kind_record
    end
  end
end
