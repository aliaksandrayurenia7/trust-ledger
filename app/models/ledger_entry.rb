class LedgerEntry < ApplicationRecord
  belongs_to :ledger_transaction

  validates :account, presence: true
  validates :amount_cents, numericality: { other_than: 0 }

  # minus is money leaving an account, plus is money arriving
  scope :for_account, ->(account) { where(account: account) }

  def self.balance_of(account)
    for_account(account).sum(:amount_cents)
  end
end
