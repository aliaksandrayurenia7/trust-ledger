class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :buyer,  null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.string  :currency, limit: 3, null: false, default: "EUR"
      t.string  :state, limit: 32, null: false, default: "created"
      t.integer :risk_score
      t.timestamps
    end

    add_index :orders, :state
  end
end
