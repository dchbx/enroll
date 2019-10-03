require "rails_helper"

describe Admin::QleKinds::UpdateService, "given:
- a update_params_validator
- a update_domain_validator
- a update_virtual_model
" do

  let(:update_params_validator) do
    instance_double(::QleKinds::UpdateParamsValidator)
  end
  let(:update_domain_validator) do 
    instance_double(::QleKinds::UpdateDomainValidator)
  end
  let(:update_virtual_model) { double }
  
  let(:subject) do
     Admin::QleKinds::UpdateService.new(
       update_params_validator: update_params_validator,
       update_domain_validator: update_domain_validator,
       update_virtual_model: update_virtual_model
     )
  end

  it "assigns the params validator" do

    expect(subject.update_params_validator).to eq update_params_validator
  end

  it "assigns the domain validator" do
    expect(subject.update_domain_validator).to eq update_domain_validator
  end

  it "assigns the virtual_model" do
    expect(subject.update_virtual_model).to eq update_virtual_model
  end
end

describe Admin::QleKinds::UpdateService, "#call" do
  let(:update_params_validator) do
    instance_double(::QleKinds::UpdateParamsValidator)
  end
  let(:update_domain_validator) do 
    instance_double(::QleKinds::UpdateDomainValidator)
  end
  let(:update_virtual_model) { double }
  
  let(:subject) do
     Admin::QleKinds::UpdateService.new(
       update_params_validator: update_params_validator,
       update_domain_validator: update_domain_validator,
       update_virtual_model: update_virtual_model
     )
  end

  let(:user) { double }
  let(:params) { double }
  let(:params_output) { double }

  before do

    allow(update_params_validator).to receive(

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
      allow(update_virtual_model).to receive(

          :new
        ).with(
          params_output
        ).and_return(
          virtual_model
        )
      allow(update_domain_validator).to receive(

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
    
    let(:virtual_model) {Admin::QleKinds::UpdateRequest.new(updated_record_params)}
    let(:updated_qle_kind_record) { double }
    let(:updated_record_params) do
      {
        id: existing_qle_kind.id,
        title: updated_title,
        market_kind: updated_market_kind,
        is_self_attested: updated_is_self_attested,
        effective_on_kinds:['date_of_event'],
        pre_event_sep_in_days: 12,
        post_event_sep_in_days:12,
        tool_tip:"tool tip",
        reason:"reason",
        action_kind:"action kind",
        start_on: "11/11/1111",
        end_on: "11/11/1111",
      }
    end

    let(:updated_title) { "Updated QLE Kind Title" }
    let(:updated_market_kind) { "shop" }
    let(:updated_is_self_attested) { false}
    let(:existing_qle_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let!(:attrs) {existing_qle_kind.attributes}
    before do

      allow(update_virtual_model).to receive(

        :new
      ).with(
        params_output
      ).and_return(
        virtual_model
      )
      allow(update_domain_validator).to receive(

        :call
      ).with(
        user: user,
        request: virtual_model,
        service: subject
      ).and_return(
        domain_validation_result
      )
      allow(QualifyingLifeEventKind).to receive(
        :update
      ).with(
        updated_record_params
      ).and_return(
        updated_qle_kind_record
      )

    end

    it "is a success" do
      result = subject.call(user, params)
      expect(result.success?).to be_truthy
    end

    it "updates the record" do
      result = subject.call(user, params)
      existing_qle_kind.reload
      expect(existing_qle_kind.attributes).to_not eq(attrs) 
    end

    it "returns the updated record" do
      result = subject.call(user, params)
      expect(result.output).to eq existing_qle_kind
    end
  end
end
