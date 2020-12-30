# frozen_string_literal: true

UIHelpers::Engine.routes.draw do
  mount FinancialAssistance::Engine,  at: './financial_assistance'
end
