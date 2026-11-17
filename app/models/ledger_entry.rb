class LedgerEntry < ApplicationRecord
  belongs_to :ledger_transaction

  validates :account, presence: true
  validates :amount_cents, numericality: { other_than: 0 }

  # minus is money leaving an account, plus is money arriving
  scope :for_account, ->(account) { where(account: account) }
  scope :for_order, ->(order_id) {
    joins(:ledger_transaction).where(ledger_transactions: { order_id: order_id })
  }

  # A balance is always summed, never stored. Pass an order to scope the
  # balance to a single case, which is what a CS representative needs.
  def self.balance_of(account, order_id: nil)
    scope = for_account(account)
    scope = scope.for_order(order_id) if order_id
    scope.sum(:amount_cents)
  end
end
