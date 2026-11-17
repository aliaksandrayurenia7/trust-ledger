class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound,   with: :not_found
  rescue_from ActiveRecord::RecordInvalid,    with: :unprocessable
  rescue_from AASM::InvalidTransition,        with: :conflict
  rescue_from Ledger::RecordTransaction::UnbalancedError, with: :unprocessable

  before_action :authenticate!

  private

  # Authorization: Bearer <token>. The role is read from the database,
  # never from a header the caller controls.
  def authenticate!
    token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
    @current_user = User.find_by(api_token: token) if token.present?

    return if @current_user

    render json: { error: "a valid bearer token is required" }, status: :unauthorized
  end

  attr_reader :current_user

  def require_support!
    return true if current_user.support?

    render json: { error: "support role required" }, status: :forbidden
    false
  end

  # Money leaves the platform only on a decision by staff.
  def require_staff!
    return true if current_user.support? || current_user.system?

    render json: { error: "support or system role required" }, status: :forbidden
    false
  end

  # A webhook from the payment provider or the courier.
  def require_system!
    return true if current_user.system?

    render json: { error: "system role required" }, status: :forbidden
    false
  end

  # Only the two people in the order, or support, may act on it.
  def require_participant!(order)
    return true if current_user.support?
    return true if [ order.buyer_id, order.seller_id ].include?(current_user.id)

    render json: { error: "you are not part of this order" }, status: :forbidden
    false
  end

  def idempotency_key!
    key = request.headers["Idempotency-Key"].presence
    return key if key

    render json: { error: "Idempotency-Key header is required" }, status: :bad_request
    nil
  end

  def not_found(error)     = render(json: { error: error.message }, status: :not_found)
  def unprocessable(error) = render(json: { error: error.message }, status: :unprocessable_entity)
  def conflict(error)      = render(json: { error: error.message }, status: :conflict)
end
