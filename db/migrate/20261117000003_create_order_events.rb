class CreateOrderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :order_events do |t|
      t.references :order, null: false, foreign_key: true
      t.string :from_state, limit: 32
      t.string :to_state,   limit: 32, null: false
      t.string :actor_type, limit: 16, null: false  # system, support, buyer, seller
      t.bigint :actor_id
      t.string :reason_code, limit: 64
      t.text   :note

      t.datetime :created_at, null: false
    end

    add_index :order_events, [:order_id, :created_at]
  end
end
