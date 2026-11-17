require "rails_helper"

RSpec.describe Order, type: :model do
  subject(:order) { create(:order) }

  it "starts in the created state" do
    expect(order.state).to eq("created")
  end

  it "moves to held once the payment is captured" do
    order.capture_payment!
    expect(order.state).to eq("held")
  end

  it "cannot pay out money that was never captured" do
    expect(order.may_release_payout?).to be(false)
    expect { order.release_payout! }.to raise_error(AASM::InvalidTransition)
  end

  it "cannot pay out while a human is still reviewing the order" do
    order.capture_payment!
    order.flag_for_review!

    expect(order.may_release_payout?).to be(false)
  end

  it "can pay out only after delivery is confirmed" do
    order.capture_payment!
    order.confirm_delivery!

    expect(order.may_release_payout?).to be(true)
    order.release_payout!
    expect(order.state).to eq("completed")
  end

  it "never leaves a final state" do
    order.capture_payment!
    order.confirm_delivery!
    order.release_payout!

    expect(order.may_refund?).to be(false)
  end

  it "rejects an order with a non positive amount" do
    expect(build(:order, amount_cents: 0)).not_to be_valid
  end
end
