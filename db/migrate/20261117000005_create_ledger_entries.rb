class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :ledger_transaction, null: false, foreign_key: true
      t.string  :account, limit: 64, null: false
      t.integer :amount_cents, null: false

      t.datetime :created_at, null: false
    end

    add_index :ledger_entries, :account
  end
end
