module Support
  class CasesController < ApplicationController
    before_action :require_support!

    def show
      order = Order.find(params[:order_id])
      render json: CaseBuilder.call(order: order)
    end

    # The queue a representative actually works from: oldest first,
    # because the longest waiting customer is the angriest one.
    def index
      orders = Order.where(state: "under_review")
      orders = orders.where("risk_score >= ?", params[:min_risk]) if params[:min_risk]

      render json: {
        count: orders.count,
        cases: orders.order(:updated_at).limit(50).map { |order| queue_row(order) }
      }
    end

    private

    def queue_row(order)
      {
        order_id: order.id,
        amount: format("%.2f", order.amount_cents / 100.0),
        risk_score: order.risk_score,
        waiting_minutes: ((Time.current - order.updated_at) / 60).round,
        top_reason: order.risk_checks.order(points: :desc).first&.rule_code
      }
    end
  end
end
