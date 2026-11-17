class DisputesController < ApplicationController
  rescue_from Disputes::Open::AlreadyOpenError, with: :conflict
  rescue_from Disputes::Resolve::InvalidResolutionError, with: :unprocessable

  def create
    order = Order.find(params[:order_id])
    return unless require_participant!(order)

    Disputes::Open.call(
      order: order,
      opened_by: side_of(order),
      reason_code: params.require(:reason_code),
      note: params[:note]
    )

    render json: Support::CaseBuilder.call(order: order.reload), status: :created
  end

  def resolve
    return unless require_support!

    key = idempotency_key!
    return unless key

    dispute = Dispute.find(params[:id])

    Disputes::Resolve.call(
      dispute: dispute,
      resolution: params.require(:resolution),
      reason_code: params.require(:reason_code),
      support_id: current_user.id,
      idempotency_key: key
    )

    render json: Support::CaseBuilder.call(order: dispute.order.reload)
  end

  private

  # Which side of the order the caller is on, taken from the order itself
  # and not from what the caller claims.
  def side_of(order)
    return "buyer" if order.buyer_id == current_user.id

    "seller"
  end
end
