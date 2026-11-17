module Disputes
  # A buyer or a seller says something went wrong. The order stops moving
  # and waits for a human. Opening a dispute never moves money.
  class Open
    class AlreadyOpenError < StandardError; end

    def self.call(order:, opened_by:, reason_code:, note: nil)
      raise AlreadyOpenError, "this order already has an open dispute" if order.disputes.open.exists?

      ActiveRecord::Base.transaction do
        dispute = order.disputes.create!(
          opened_by: opened_by,
          reason_code: reason_code,
          state: "open"
        )

        if order.may_flag_for_review?
          previous = order.state
          order.flag_for_review!
          Orders::Events.record(order, from_state: previous, to_state: "under_review",
                                actor_type: opened_by, reason_code: "dispute_opened", note: note)
        end

        dispute
      end
    end
  end
end
