class Order < ApplicationRecord
  include AASM

  belongs_to :buyer,  class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :events,               class_name: "OrderEvent", dependent: :destroy
  has_many :ledger_transactions,  dependent: :destroy
  has_many :risk_checks,          dependent: :destroy
  has_many :disputes,             dependent: :destroy

  validates :amount_cents, numericality: { greater_than: 0 }

  aasm column: :state do
    state :created, initial: true
    state :held
    state :under_review
    state :payout_ready
    state :completed
    state :refunded

    event :capture_payment do
      transitions from: :created, to: :held
    end

    event :flag_for_review do
      transitions from: :held, to: :under_review
    end

    event :approve do
      transitions from: :under_review, to: :held
    end

    event :confirm_delivery do
      transitions from: :held, to: :payout_ready
    end

    event :release_payout do
      transitions from: :payout_ready, to: :completed
    end

    event :refund do
      transitions from: [ :held, :under_review, :payout_ready ], to: :refunded
    end
  end
end
