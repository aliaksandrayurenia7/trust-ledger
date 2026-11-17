module Ledger
  # Money moves from the buyer into escrow and stays there.
  class CapturePayment
    def self.call(order:, idempotency_key:)
      RecordTransaction.call(
        order: order,
        kind: "payment_captured",
        idempotency_key: idempotency_key,
        entries: [
          { account: Accounts.buyer(order.buyer_id), amount_cents: -order.amount_cents },
          { account: Accounts.escrow(order.id),      amount_cents:  order.amount_cents }
        ]
      )
    end
  end
end
