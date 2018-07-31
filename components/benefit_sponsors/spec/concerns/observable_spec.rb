require 'rails_helper'

if !defined?($observable_shared_spec_defined)
  $observable_shared_spec_defined = 1
  RSpec.shared_examples_for "observable" do |factory_name=nil, *traits|
    let(:factory) { factory_name || described_class.to_s.underscore.gsub('/', '_').to_sym }
    let(:model) {create factory, *traits }

    before do
      allow(model).to receive(:notify_observers)
      model.touch
      model.save
    end

    it 'calls notify_observers after update' do
      expect(model).to have_received(:notify_observers)
    end
  end
end
