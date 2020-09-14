# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class AddFinancialAssistanceEligibilityDetermination
      send(:include, Dry::Monads[:result, :do])

      def call(params:)
        values = yield validate(params) #application_contract
        result = yield add_determination(values)

        Success(result)
      end


      private

      def validate(params)
        Validators::Families::EligibilityDeterminationContract.new.call(params)
      end

      def add_determination(values)
     family  = Operations::Families::Find.new.call(values[:family_id])

        #deactivate any existing eligibility determination using Operation

       # application[:eligibility_determination] for each do
        #create use faa eligibility determination  to create tax household and tax household members and eligibility determination
       # end
        update_family_attributes(application)

        Success(result)
      end


      def update_family_attributes(application)
        family.e_case_id = application[:integrated_case_id]
        ###any of the family attributes
        Success(family.save!)
      end

    end
  end
end
