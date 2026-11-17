class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :role, limit: 16, null: false   # buyer, seller, support
      t.string :country, limit: 2
      t.timestamps
    end
  end
end
