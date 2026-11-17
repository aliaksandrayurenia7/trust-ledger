class CreateRiskChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :risk_checks do |t|
      t.references :order, null: false, foreign_key: true
      t.string  :rule_code, limit: 64, null: false
      t.integer :points, null: false
      t.json    :details

      t.datetime :created_at, null: false
    end
  end
end
