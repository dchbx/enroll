class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :workflow, default: '{}'
      t.string :results, default: '{}'

      t.timestamps null: false
    end
  end
end
