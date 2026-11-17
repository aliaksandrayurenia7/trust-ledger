require "rails_helper"

RSpec.describe "Support cases API", type: :request do
  let(:support) { create(:support) }

  def json = JSON.parse(response.body)

  it "is closed without a token" do
    get "/support/cases"

    expect(response).to have_http_status(:unauthorized)
  end

  it "does not let a buyer read the support queue" do
    get "/support/cases", headers: auth(create(:user))

    expect(response).to have_http_status(:forbidden)
  end

  it "shows the queue of orders waiting for a human" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 20_000)
    Risk::Engine.call(order: order)
    order.capture_payment!
    order.flag_for_review!

    get "/support/cases", headers: auth(support)

    expect(response).to have_http_status(:ok)
    expect(json["count"]).to eq(1)
    expect(json["cases"].first["order_id"]).to eq(order.id)
    expect(json["cases"].first["top_reason"]).to eq("new_account_high_value")
  end

  it "explains in words why an order was held" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 20_000)
    Orders::CapturePayment.call(order: order, idempotency_key: "pay-1")

    get "/support/cases/#{order.id}", headers: auth(support)

    expect(response).to have_http_status(:ok)
    expect(json["why_held"].map { |r| r["rule"] }).to include("new_account_high_value")
    expect(json["why_held"].first["explain"]).to be_present
  end

  it "gives a customer safe message that never names a risk rule" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 20_000)
    Orders::CapturePayment.call(order: order, idempotency_key: "pay-1")

    get "/support/cases/#{order.id}", headers: auth(support)

    message = json["customer_message"]
    expect(message).to be_present
    expect(message).not_to include("rule")
    expect(message).not_to match(/risk|fraud|account is \d+ days old/i)
    expect(json["why_held"]).to be_present
  end
end
