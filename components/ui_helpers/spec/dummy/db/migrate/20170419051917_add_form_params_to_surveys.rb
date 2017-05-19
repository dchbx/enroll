class AddFormParamsToSurveys < ActiveRecord::Migration
  def change
  	add_column :surveys, :form_params, :string, default: '{}'
  end
end
