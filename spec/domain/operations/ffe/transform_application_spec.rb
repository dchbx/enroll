# frozen_string_literal: true

RSpec.describe Operations::Ffe::TransformApplication, type: :model, dbclean: :after_each do
  
    context 'for success flow' do
  
      before do
        example_output_hash = JSON.parse(File.read(Pathname.pwd.join("spec/test_data/family_transform_result.json")))
        @result = subject.call(example_output_hash)
        family.reload
      end
  
      context 'success' do
        it 'should return success' do
          expect(@result).to be_a Dry::Monads::Result::Success
        end
      end
    end
  end
  