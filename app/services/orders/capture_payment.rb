module Orders
  # The whole payment step in one place: score the order, move the money,
  # change the state, and write down why.
  class CapturePayment
    def self.call(order:, idempotency_key:)
      ActiveRecord::Base.transaction do
        Ledger::CapturePayment.call(order: order, idempotency_key: idempotency_key)

        order.capture_payment! if order.may_capture_payment?
        Events.record(order, to_state: "held", actor_type: "system", reason_code: "payment_captured")

        score = Risk::Engine.call(order: order)

        if Risk::Decision.for(score) == :needs_human && order.may_flag_for_review?
          order.flag_for_review!
          Events.record(order, from_state: "held", to_state: "under_review",
                        actor_type: "system", reason_code: "risk_threshold_exceeded")
        end

        order.reload
      end
    end
  end
end
