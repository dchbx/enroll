module Admin
  module QleKinds
    class CreateRequest
      extend Dry::Initializer

      class UsDateCoercer
        def self.coerce(string)
          formated_string = Date.parse(string).strftime("%m/%d/%Y") rescue nil
          if formated_string == nil
            return Date.strptime(string, "%m/%d/%Y") rescue nil
          end
          Date.strptime(formated_string, "%m/%d/%Y") rescue nil
        end
      end
  
      option :title, Dry::Types['coercible.string']
      option :market_kind, Dry::Types['coercible.string']
      option :is_self_attested, Dry::Types['params.bool']
      option :visible_to_customer, Dry::Types['params.bool'], optional: true
      option :effective_on_kinds, Dry::Types['coercible.array']
      option :post_event_sep_in_days, Dry::Types['coercible.string']
      option :pre_event_sep_in_days, Dry::Types['coercible.string']
      option :tool_tip, Dry::Types['coercible.string'], optional: true
      option :reason, Dry::Types['coercible.string'], optional: true
      option :is_active, Dry::Types['params.bool'], optional: true
      option :start_on, type: ->(val) { UsDateCoercer.coerce(val) }, optional: true
      option :end_on, type: ->(val) { UsDateCoercer.coerce(val) }, optional: true
      option :custom_qle_questions, Dry::Types['coercible.array'], optional: true

    end
  end
end