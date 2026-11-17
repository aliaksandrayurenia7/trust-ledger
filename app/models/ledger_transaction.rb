class LedgerTransaction < ApplicationRecord
  KINDS = %w[payment_captured payout_released refund].freeze

  belongs_to :order
  has_many :entries, class_name: "LedgerEntry", dependent: :destroy

  validates :kind, inclusion: { in: KINDS }
  validates :idempotency_key, presence: true, uniqueness: true

  # a transaction is only valid if its entries sum to zero
  def balanced?
    entries.sum(:amount_cents).zero?
  end
end
