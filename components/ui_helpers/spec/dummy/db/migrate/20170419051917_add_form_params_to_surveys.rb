# frozen_string_literal: true

class AddFormParamsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :form_params, :string, default: '{}'
  end
end
