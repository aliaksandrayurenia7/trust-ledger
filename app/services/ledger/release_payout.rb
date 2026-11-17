module Ledger
  # Escrow is emptied: the seller gets the amount minus the platform fee.
  class ReleasePayout
    def self.call(order:, idempotency_key:)
      fee = fee_for(order)
      payout = order.amount_cents - fee

      RecordTransaction.call(
        order: order,
        kind: "payout_released",
        idempotency_key: idempotency_key,
        entries: [
          { account: Accounts.escrow(order.id),        amount_cents: -order.amount_cents },
          { account: Accounts.seller(order.seller_id), amount_cents: payout },
          { account: Accounts::PLATFORM_FEE,           amount_cents: fee }
        ]
      )
    end

    def self.fee_for(order)
      percent = ENV.fetch("PLATFORM_FEE_PERCENT", 5).to_i
      (order.amount_cents * percent / 100.0).round
    end
  end
end
