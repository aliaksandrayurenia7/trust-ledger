require "rails_helper"

RSpec.describe "Disputes API", type: :request do
  let(:buyer)  { create(:user) }
  let(:seller) { create(:seller, created_at: 1.year.ago) }
  let(:order)  { create(:order, buyer: buyer, seller: seller, amount_cents: 5_000) }
  let(:support_user) { create(:support) }
  let(:support_headers) { { "X-Role" => "support", "X-User-Id" => support_user.id.to_s } }

  def json = JSON.parse(response.body)

  before { post "/orders/#{order.id}/payment", headers: { "Idempotency-Key" => "pay-1" } }

  describe "POST /orders/:id/disputes" do
    it "stops the order and sends it to a human" do
      post "/orders/#{order.id}/disputes",
           params: { opened_by: "buyer", reason_code: "item_not_as_described" }

      expect(response).to have_http_status(:created)
      expect(json.dig("order", "state")).to eq("under_review")
      expect(order.reload.disputes.open.count).to eq(1)
    end

    it "refuses a second dispute on the same order" do
      2.times do
        post "/orders/#{order.id}/disputes",
             params: { opened_by: "buyer", reason_code: "item_not_as_described" }
      end

      expect(response).to have_http_status(:conflict)
      expect(order.reload.disputes.count).to eq(1)
    end

    it "moves no money when a dispute is opened" do
      post "/orders/#{order.id}/disputes",
           params: { opened_by: "buyer", reason_code: "item_not_as_described" }

      expect(json.dig("money", "held_in_escrow")).to eq("50.00")
      expect(json.dig("money", "paid_to_seller")).to eq("0.00")
    end
  end

  describe "POST /disputes/:id/resolve" do
    let(:dispute) do
      Disputes::Open.call(order: order, opened_by: "buyer", reason_code: "item_not_as_described")
    end

    it "is closed to everyone except support" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "buyer_wins", reason_code: "support_refunded" },
           headers: { "Idempotency-Key" => "res-1" }

      expect(response).to have_http_status(:forbidden)
    end

    it "requires an idempotency key before touching money" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "buyer_wins", reason_code: "support_refunded" },
           headers: support_headers

      expect(response).to have_http_status(:bad_request)
    end

    it "refunds the buyer when the buyer wins" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "buyer_wins", reason_code: "support_refunded" },
           headers: support_headers.merge("Idempotency-Key" => "res-1")

      expect(json.dig("order", "state")).to eq("refunded")
      expect(json.dig("money", "held_in_escrow")).to eq("0.00")
      expect(json.dig("money", "buyer_paid")).to eq("0.00")
    end

    it "pays the seller when the seller wins" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "seller_wins", reason_code: "support_approved" },
           headers: support_headers.merge("Idempotency-Key" => "res-1")

      expect(json.dig("order", "state")).to eq("completed")
      expect(json.dig("money", "paid_to_seller")).to eq("47.50")
    end

    it "rejects a resolution it does not know" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "coin_flip", reason_code: "whatever" },
           headers: support_headers.merge("Idempotency-Key" => "res-1")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "records who decided and why" do
      post "/disputes/#{dispute.id}/resolve",
           params: { resolution: "buyer_wins", reason_code: "support_refunded" },
           headers: support_headers.merge("Idempotency-Key" => "res-1")

      event = order.reload.events.last
      expect(event.actor_type).to eq("support")
      expect(event.actor_id).to eq(support_user.id)
      expect(event.reason_code).to eq("support_refunded")

      expect(dispute.reload.state).to eq("resolved")
      expect(dispute.assigned_support_id).to eq(support_user.id)
      expect(dispute.resolved_at).to be_present
    end
  end
end
