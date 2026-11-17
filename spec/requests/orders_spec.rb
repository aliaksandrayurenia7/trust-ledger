require "rails_helper"

RSpec.describe "Orders API", type: :request do
  let(:buyer)       { create(:user) }
  let(:seller)      { create(:seller, created_at: 1.year.ago) }
  let(:system_user) { create(:system_user) }
  let(:support)     { create(:support) }
  let(:order)       { create(:order, buyer: buyer, seller: seller, amount_cents: 5_000) }

  def json = JSON.parse(response.body)

  describe "authentication" do
    it "refuses a request with no token" do
      get "/orders/#{order.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses a made up token" do
      get "/orders/#{order.id}", headers: { "Authorization" => "Bearer not-a-real-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not let a stranger read someone else's order" do
      stranger = create(:user)

      get "/orders/#{order.id}", headers: auth(stranger)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /orders" do
    it "creates an order owned by the caller" do
      post "/orders", params: { seller_id: seller.id, amount_cents: 5_000 }, headers: auth(buyer)

      expect(response).to have_http_status(:created)
      expect(json.dig("order", "state")).to eq("created")
      expect(Order.last.buyer_id).to eq(buyer.id)
    end

    it "ignores a buyer_id the caller tries to fake" do
      victim = create(:user)

      post "/orders",
           params: { buyer_id: victim.id, seller_id: seller.id, amount_cents: 5_000 },
           headers: auth(buyer)

      expect(Order.last.buyer_id).to eq(buyer.id)
    end
  end

  describe "POST /orders/:id/payment" do
    it "is closed to a buyer, it is a payment provider webhook" do
      post "/orders/#{order.id}/payment", headers: auth(buyer, "Idempotency-Key" => "pay-1")

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses to move money without an idempotency key" do
      post "/orders/#{order.id}/payment", headers: auth(system_user)

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]).to match(/Idempotency-Key/)
    end

    it "holds the money in escrow" do
      post "/orders/#{order.id}/payment", headers: auth(system_user, "Idempotency-Key" => "pay-1")

      expect(response).to have_http_status(:ok)
      expect(json.dig("order", "state")).to eq("held")
      expect(json.dig("money", "held_in_escrow")).to eq("50.00")
    end

    it "never charges twice when the same request arrives again" do
      2.times do
        post "/orders/#{order.id}/payment", headers: auth(system_user, "Idempotency-Key" => "pay-1")
      end

      expect(json.dig("money", "held_in_escrow")).to eq("50.00")
      expect(LedgerTransaction.count).to eq(1)
    end
  end

  describe "the full happy path" do
    it "pays the seller and empties escrow" do
      post "/orders/#{order.id}/payment",  headers: auth(system_user, "Idempotency-Key" => "pay-1")
      post "/orders/#{order.id}/delivery", headers: auth(system_user, "Idempotency-Key" => "del-1")
      post "/orders/#{order.id}/payout",   headers: auth(support, "Idempotency-Key" => "out-1")

      expect(json.dig("order", "state")).to eq("completed")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
      expect(json.dig("money", "paid_to_seller")).to eq("47.50")
    end

    it "does not let the seller pay themselves" do
      post "/orders/#{order.id}/payment", headers: auth(system_user, "Idempotency-Key" => "pay-1")
      post "/orders/#{order.id}/payout",  headers: auth(seller, "Idempotency-Key" => "out-1")

      expect(response).to have_http_status(:forbidden)
      expect(order.reload.state).to eq("held")
    end
  end

  describe "POST /orders/:id/refund" do
    it "gives the money back and takes no fee" do
      post "/orders/#{order.id}/payment", headers: auth(system_user, "Idempotency-Key" => "pay-1")
      post "/orders/#{order.id}/refund",  headers: auth(support, "Idempotency-Key" => "ref-1")

      expect(json.dig("order", "state")).to eq("refunded")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
      expect(json.dig("money", "buyer_paid")).to eq("0.00")
    end

    it "does not let a buyer refund themselves" do
      post "/orders/#{order.id}/payment", headers: auth(system_user, "Idempotency-Key" => "pay-1")
      post "/orders/#{order.id}/refund",  headers: auth(buyer, "Idempotency-Key" => "ref-1")

      expect(response).to have_http_status(:forbidden)
    end
  end
end
