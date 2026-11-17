require "rails_helper"

RSpec.describe "Orders API", type: :request do
  let(:buyer)  { create(:user) }
  let(:seller) { create(:seller, created_at: 1.year.ago) }

  def json = JSON.parse(response.body)

  describe "POST /orders" do
    it "creates an order in the created state" do
      post "/orders", params: { buyer_id: buyer.id, seller_id: seller.id, amount_cents: 5_000 }

      expect(response).to have_http_status(:created)
      expect(json.dig("order", "state")).to eq("created")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
    end
  end

  describe "POST /orders/:id/payment" do
    let(:order) { create(:order, buyer: buyer, seller: seller, amount_cents: 5_000) }

    it "refuses to move money without an idempotency key" do
      post "/orders/#{order.id}/payment"

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]).to match(/Idempotency-Key/)
    end

    it "holds the money in escrow" do
      post "/orders/#{order.id}/payment", headers: { "Idempotency-Key" => "pay-1" }

      expect(response).to have_http_status(:ok)
      expect(json.dig("order", "state")).to eq("held")
      expect(json.dig("money", "held_in_escrow")).to eq("50.00")
    end

    it "never charges twice when the same request arrives again" do
      2.times { post "/orders/#{order.id}/payment", headers: { "Idempotency-Key" => "pay-1" } }

      expect(json.dig("money", "held_in_escrow")).to eq("50.00")
      expect(LedgerTransaction.count).to eq(1)
    end
  end

  describe "the full happy path" do
    let(:order) { create(:order, buyer: buyer, seller: seller, amount_cents: 5_000) }

    it "pays the seller and empties escrow" do
      post "/orders/#{order.id}/payment",  headers: { "Idempotency-Key" => "pay-1" }
      post "/orders/#{order.id}/delivery", headers: { "Idempotency-Key" => "deliver-1" }
      post "/orders/#{order.id}/payout",   headers: { "Idempotency-Key" => "payout-1" }

      expect(json.dig("order", "state")).to eq("completed")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
      expect(json.dig("money", "paid_to_seller")).to eq("47.50")
    end
  end

  describe "POST /orders/:id/refund" do
    let(:order) { create(:order, buyer: buyer, seller: seller, amount_cents: 5_000) }

    it "gives the money back and takes no fee" do
      post "/orders/#{order.id}/payment", headers: { "Idempotency-Key" => "pay-1" }
      post "/orders/#{order.id}/refund",  headers: { "Idempotency-Key" => "refund-1" }

      expect(json.dig("order", "state")).to eq("refunded")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
      expect(json.dig("money", "buyer_paid")).to eq("0.00")
    end
  end
end
