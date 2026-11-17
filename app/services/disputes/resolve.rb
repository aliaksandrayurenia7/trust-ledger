module Disputes
  # A CS representative decides. The decision moves the money and is
  # always stored with a reason, so the case can be explained later.
  class Resolve
    RESOLUTIONS = %w[buyer_wins seller_wins].freeze

    class InvalidResolutionError < StandardError; end

    def self.call(dispute:, resolution:, reason_code:, support_id: nil, idempotency_key:)
      raise InvalidResolutionError, "unknown resolution" unless RESOLUTIONS.include?(resolution)

      order = dispute.order

      ActiveRecord::Base.transaction do
        if resolution == "buyer_wins"
          Ledger::Refund.call(order: order, idempotency_key: idempotency_key)
          order.refund!
          Orders::Events.record(order, to_state: "refunded", actor_type: "support",
                                actor_id: support_id, reason_code: reason_code)
        else
          order.approve! if order.may_approve?
          order.confirm_delivery! if order.may_confirm_delivery?
          Ledger::ReleasePayout.call(order: order, idempotency_key: idempotency_key)
          order.release_payout!
          Orders::Events.record(order, to_state: "completed", actor_type: "support",
                                actor_id: support_id, reason_code: reason_code)
        end

        dispute.update!(
          state: "resolved",
          resolution: resolution,
          assigned_support_id: support_id,
          resolved_at: Time.current
        )

        dispute
      end
    end
  end
end
