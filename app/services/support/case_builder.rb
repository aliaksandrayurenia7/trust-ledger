module Support
  # One call gives a CS representative everything needed to decide:
  # what happened, where the money is, why it was held, and what can be done now.
  class CaseBuilder
    EXPLANATIONS = {
      "new_account_high_value" => "Seller account is %{seller_age_days} days old and the order is above 40 EUR",
      "seller_many_cancellations" => "Seller had %{cancellations_last_30_days} cancellations in the last 30 days",
      "high_value_order" => "Order amount is above 100 EUR"
    }.freeze

    def self.call(order:) = new(order).call

    def initialize(order) = @order = order

    def call
      {
        order: order_summary,
        why_held: why_held,
        timeline: timeline,
        money: money,
        available_actions: available_actions,
        sla: sla
      }
    end

    private

    attr_reader :order

    def order_summary
      {
        id: order.id,
        state: order.state,
        amount: format_money(order.amount_cents),
        currency: order.currency,
        risk_score: order.risk_score
      }
    end

    def why_held
      order.risk_checks.map do |check|
        template = EXPLANATIONS.fetch(check.rule_code, check.rule_code)
        {
          rule: check.rule_code,
          points: check.points,
          explain: format(template, check.details.symbolize_keys)
        }
      end
    end

    def timeline
      order.events.order(:created_at).map do |event|
        {
          at: event.created_at.iso8601,
          event: event.to_state,
          actor: event.actor_type,
          reason_code: event.reason_code
        }.compact
      end
    end

    def money
      {
        buyer_paid: format_money(-LedgerEntry.balance_of(Ledger::Accounts.buyer(order.buyer_id), order_id: order.id)),
        held_in_escrow: format_money(LedgerEntry.balance_of(Ledger::Accounts.escrow(order.id), order_id: order.id)),
        paid_to_seller: format_money(LedgerEntry.balance_of(Ledger::Accounts.seller(order.seller_id), order_id: order.id)),
        platform_fee: format_money(Ledger::ReleasePayout.fee_for(order))
      }
    end

    def available_actions
      actions = []
      actions << action("approve_payout", "POST /orders/#{order.id}/payout") if order.may_confirm_delivery? || order.may_release_payout?
      actions << action("refund_buyer", "POST /orders/#{order.id}/refund") if order.may_refund?
      actions
    end

    def action(name, endpoint) = { action: name, endpoint: endpoint }

    def sla
      return nil unless order.state == "under_review"

      waiting = ((Time.current - order.updated_at) / 60).round
      { waiting_for_human_minutes: waiting, target_minutes: 60 }
    end

    def format_money(cents) = format("%.2f", cents / 100.0)
  end
end
