class DisputesController < ApplicationController
  rescue_from Disputes::Open::AlreadyOpenError, with: :conflict
  rescue_from Disputes::Resolve::InvalidResolutionError, with: :unprocessable

  def create
    order = Order.find(params[:order_id])

    Disputes::Open.call(
      order: order,
      opened_by: params.require(:opened_by),
      reason_code: params.require(:reason_code),
      note: params[:note]
    )

    render json: Support::CaseBuilder.call(order: order.reload), status: :created
  end

  def resolve
    return unless support_role?

    key = idempotency_key!
    return unless key

    dispute = Dispute.find(params[:id])

    Disputes::Resolve.call(
      dispute: dispute,
      resolution: params.require(:resolution),
      reason_code: params.require(:reason_code),
      support_id: current_user_id,
      idempotency_key: key
    )

    render json: Support::CaseBuilder.call(order: dispute.order.reload)
  end

  private

  def support_role?
    return true if current_role == "support"

    render json: { error: "support role required" }, status: :forbidden
    false
  end
end
