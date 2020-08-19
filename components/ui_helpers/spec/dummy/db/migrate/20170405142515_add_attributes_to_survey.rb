class AddAttributesToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :smoker, :boolean
    add_column :surveys, :first_name, :string
    add_column :surveys, :last_name, :string
    add_column :surveys, :address, :string, default: '{}'
  end
end
