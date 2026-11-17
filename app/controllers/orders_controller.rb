class OrdersController < ApplicationController
  def create
    attrs = order_params
    attrs[:buyer_id] = current_user.id unless current_user.support? || current_user.system?

    order = Order.create!(attrs)
    render json: Support::CaseBuilder.call(order: order), status: :created
  end

  def show
    order = find_order
    return unless require_participant!(order)

    render json: Support::CaseBuilder.call(order: order)
  end

  # Called by the payment provider, not by a person.
  def payment
    return unless require_system!

    key = idempotency_key!
    return unless key

    order = Orders::CapturePayment.call(order: find_order, idempotency_key: key)
    render json: Support::CaseBuilder.call(order: order)
  end

  # Called by the courier.
  def delivery
    return unless require_system!

    key = idempotency_key!
    return unless key

    order = find_order
    order.confirm_delivery!
    Orders::Events.record(order, from_state: "held", to_state: "payout_ready",
                          actor_type: "system", actor_id: current_user.id,
                          reason_code: "delivery_confirmed")

    render json: Support::CaseBuilder.call(order: order.reload)
  end

  def payout
    return unless require_staff!

    key = idempotency_key!
    return unless key

    order = find_order

    ActiveRecord::Base.transaction do
      order.confirm_delivery! if order.may_confirm_delivery?
      Ledger::ReleasePayout.call(order: order, idempotency_key: key)
      order.release_payout!
      Orders::Events.record(order, from_state: "payout_ready", to_state: "completed",
                            actor_type: current_user.role, actor_id: current_user.id,
                            reason_code: params[:reason_code] || "payout_sent")
    end

    render json: Support::CaseBuilder.call(order: order.reload)
  end

  def refund
    return unless require_staff!

    key = idempotency_key!
    return unless key

    order = find_order

    ActiveRecord::Base.transaction do
      Ledger::Refund.call(order: order, idempotency_key: key)
      order.refund!
      Orders::Events.record(order, to_state: "refunded",
                            actor_type: current_user.role, actor_id: current_user.id,
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
