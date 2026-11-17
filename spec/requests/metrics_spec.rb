require "rails_helper"

RSpec.describe "Metrics", type: :request do
  def json = JSON.parse(response.body)

  it "reports health" do
    get "/health"

    expect(response).to have_http_status(:ok)
    expect(json["status"]).to eq("ok")
    expect(json["database"]).to be(true)
  end

  it "counts orders by state and money still held" do
    seller = create(:seller, created_at: 1.year.ago)
    order  = create(:order, seller: seller, amount_cents: 5_000)
    post "/orders/#{order.id}/payment", headers: { "Idempotency-Key" => "pay-1" }

    get "/metrics"

    expect(response).to have_http_status(:ok)
    expect(json["orders_by_state"]["held"]).to eq(1)
    expect(json["money_held_in_escrow"]).to eq("50.00")
    expect(json["waiting_for_human"]).to eq(0)
  end

  it "shows how many finished orders never needed a human" do
    seller = create(:seller, created_at: 1.year.ago)
    order  = create(:order, seller: seller, amount_cents: 5_000)
    post "/orders/#{order.id}/payment",  headers: { "Idempotency-Key" => "pay-1" }
    post "/orders/#{order.id}/delivery", headers: { "Idempotency-Key" => "del-1" }
    post "/orders/#{order.id}/payout",   headers: { "Idempotency-Key" => "out-1" }

    get "/metrics"

    expect(json["auto_resolved_share"]).to eq(100.0)
  end
end
