Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Every log line carries what a person would ask about first.
  config.lograge.custom_payload do |controller|
    {
      role: controller.request.headers["X-Role"],
      user_id: controller.request.headers["X-User-Id"],
      idempotency_key: controller.request.headers["Idempotency-Key"],
      request_id: controller.request.request_id
    }.compact
  end
end
