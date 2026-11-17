module Ledger
  # Escrow is emptied back to the buyer. No fee is taken on a refund.
  class Refund
    def self.call(order:, idempotency_key:)
      RecordTransaction.call(
        order: order,
        kind: "refund",
        idempotency_key: idempotency_key,
        entries: [
          { account: Accounts.escrow(order.id),      amount_cents: -order.amount_cents },
          { account: Accounts.buyer(order.buyer_id), amount_cents:  order.amount_cents }
        ]
      )
    end
  end
end
