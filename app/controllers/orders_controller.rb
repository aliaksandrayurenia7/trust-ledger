class OrdersController < ApplicationController
  def create
    order = Order.create!(order_params)
    render json: Support::CaseBuilder.call(order: order), status: :created
  end

  def show
    render json: Support::CaseBuilder.call(order: find_order)
  end

  def payment
    key = idempotency_key!
    return unless key

    order = Orders::CapturePayment.call(order: find_order, idempotency_key: key)
    render json: Support::CaseBuilder.call(order: order)
  end

  def delivery
    key = idempotency_key!
    return unless key

    order = find_order
    order.confirm_delivery!
    Orders::Events.record(order, from_state: "held", to_state: "payout_ready",
                          actor_type: "system", reason_code: "delivery_confirmed")

    render json: Support::CaseBuilder.call(order: order.reload)
  end

  def payout
    key = idempotency_key!
    return unless key

    order = find_order

    ActiveRecord::Base.transaction do
      order.confirm_delivery! if order.may_confirm_delivery?
      Ledger::ReleasePayout.call(order: order, idempotency_key: key)
      order.release_payout!
      Orders::Events.record(order, from_state: "payout_ready", to_state: "completed",
                            actor_type: current_role, actor_id: current_user_id,
                            reason_code: params[:reason_code] || "payout_sent")
    end

    render json: Support::CaseBuilder.call(order: order.reload)
  end

  def refund
    key = idempotency_key!
    return unless key

    order = find_order

    ActiveRecord::Base.transaction do
      Ledger::Refund.call(order: order, idempotency_key: key)
      order.refund!
      Orders::Events.record(order, to_state: "refunded",
                            actor_type: current_role, actor_id: current_user_id,
                            reason_code: params[:reason_code] || "refunded")
    end

    render json: Support::CaseBuilder.call(order: order.reload)
  end

  private

  def find_order = Order.find(params[:id])

  def order_params
    params.permit(:buyer_id, :seller_id, :amount_cents, :currency)
  end
end
