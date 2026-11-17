require "rails_helper"

RSpec.describe Risk::Engine do
  it "gives a clean order a score of zero" do
    seller = create(:seller, created_at: 1.year.ago)
    order  = create(:order, seller: seller, amount_cents: 2_000)

    expect(described_class.call(order: order)).to eq(0)
    expect(order.risk_checks).to be_empty
  end

  it "flags a new seller asking for a lot of money" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 5_000)

    expect(described_class.call(order: order)).to eq(40)
    expect(order.risk_checks.pluck(:rule_code)).to include("new_account_high_value")
  end

  it "adds up the points of every rule that fired" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 20_000)

    expect(described_class.call(order: order)).to eq(65)
    expect(order.risk_checks.count).to eq(2)
  end

  it "stores why each rule fired so a human can read it" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 5_000)
    described_class.call(order: order)

    check = order.risk_checks.find_by(rule_code: "new_account_high_value")
    expect(check.details["seller_age_days"]).to eq(1)
  end

  it "never scores above 100" do
    seller = create(:seller, created_at: 1.day.ago)
    order  = create(:order, seller: seller, amount_cents: 20_000)
    create_list(:order, 3, seller: seller, state: "refunded", updated_at: 1.day.ago)

    expect(described_class.call(order: order)).to be <= 100
  end

  it "sends a high score to a human and a low one through" do
    expect(Risk::Decision.for(80)).to eq(:needs_human)
    expect(Risk::Decision.for(50)).to eq(:extended_hold)
    expect(Risk::Decision.for(10)).to eq(:auto_hold)
  end
end
