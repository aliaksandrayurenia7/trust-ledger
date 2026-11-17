class MetricsController < ApplicationController
  # Numbers a support lead actually looks at, not generic server stats.
  def show
    render json: {
      orders_by_state: Order.group(:state).count,
      waiting_for_human: Order.where(state: "under_review").count,
      oldest_waiting_minutes: oldest_waiting_minutes,
      auto_resolved_share: auto_resolved_share,
      money_held_in_escrow: format("%.2f", escrow_total / 100.0),
      open_disputes: Dispute.open.count
    }
  end

  private

  def oldest_waiting_minutes
    oldest = Order.where(state: "under_review").minimum(:updated_at)
    return 0 unless oldest

    ((Time.current - oldest) / 60).round
  end

  # How many orders went through without a human touching them.
  def auto_resolved_share
    finished = Order.where(state: %w[completed refunded]).count
    return 0.0 if finished.zero?

    touched_by_human = OrderEvent.where(actor_type: "support")
                                 .distinct
                                 .count(:order_id)

    ((finished - touched_by_human).to_f / finished * 100).round(1)
  end

  def escrow_total
    LedgerEntry.where("account LIKE 'escrow:%'").sum(:amount_cents)
  end
end
