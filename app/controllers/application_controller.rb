class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound,   with: :not_found
  rescue_from ActiveRecord::RecordInvalid,    with: :unprocessable
  rescue_from AASM::InvalidTransition,        with: :conflict
  rescue_from Ledger::RecordTransaction::UnbalancedError, with: :unprocessable

  private

  # No real authentication in this project. The caller states its role in a
  # header, which is enough to show how support actions are attributed.
  def current_role = request.headers["X-Role"].presence || "buyer"
  def current_user_id = request.headers["X-User-Id"].presence

  def require_support!
    return if current_role == "support"

    render json: { error: "support role required" }, status: :forbidden
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
