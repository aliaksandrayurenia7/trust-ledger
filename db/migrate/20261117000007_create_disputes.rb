class CreateDisputes < ActiveRecord::Migration[8.1]
  def change
    create_table :disputes do |t|
      t.references :order, null: false, foreign_key: true
      t.string :opened_by,   limit: 16, null: false  # buyer, seller
      t.string :reason_code, limit: 64, null: false
      t.string :state, limit: 16, null: false, default: "open"
      t.string :resolution, limit: 16                # buyer_wins, seller_wins
      t.references :assigned_support, foreign_key: { to_table: :users }

      t.datetime :resolved_at
      t.timestamps
    end

    add_index :disputes, :state
  end
end
