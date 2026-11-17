require "rails_helper"

RSpec.describe "Ledger" do
  let(:order) { create(:order, amount_cents: 5_000) }

  def escrow_balance
    LedgerEntry.balance_of(Ledger::Accounts.escrow(order.id))
  end

  describe Ledger::RecordTransaction do
    it "refuses entries that do not sum to zero" do
      expect {
        described_class.call(
          order: order,
          kind: "payment_captured",
          idempotency_key: "broken",
          entries: [{ account: "buyer:1", amount_cents: -100 }]
        )
      }.to raise_error(Ledger::RecordTransaction::UnbalancedError)
    end

    it "writes nothing when the entries are unbalanced" do
      begin
        described_class.call(
          order: order,
          kind: "payment_captured",
          idempotency_key: "broken",
          entries: [{ account: "buyer:1", amount_cents: -100 }]
        )
      rescue Ledger::RecordTransaction::UnbalancedError
        nil
      end

      expect(LedgerTransaction.count).to eq(0)
      expect(LedgerEntry.count).to eq(0)
    end
  end

  describe "capturing a payment" do
    it "moves the money into escrow" do
      Ledger::CapturePayment.call(order: order, idempotency_key: "pay-1")

      expect(escrow_balance).to eq(5_000)
      expect(LedgerEntry.balance_of(Ledger::Accounts.buyer(order.buyer_id))).to eq(-5_000)
    end

    it "never pays twice for the same idempotency key" do
      2.times { Ledger::CapturePayment.call(order: order, idempotency_key: "pay-1") }

      expect(LedgerTransaction.count).to eq(1)
      expect(escrow_balance).to eq(5_000)
    end
  end

  describe "releasing a payout" do
    before { Ledger::CapturePayment.call(order: order, idempotency_key: "pay-1") }

    it "empties escrow and splits the money between seller and platform" do
      Ledger::ReleasePayout.call(order: order, idempotency_key: "payout-1")

      expect(escrow_balance).to eq(0)
      expect(LedgerEntry.balance_of(Ledger::Accounts.seller(order.seller_id))).to eq(4_750)
      expect(LedgerEntry.balance_of(Ledger::Accounts::PLATFORM_FEE)).to eq(250)
    end

    it "never pays the seller twice for the same key" do
      2.times { Ledger::ReleasePayout.call(order: order, idempotency_key: "payout-1") }

      expect(LedgerEntry.balance_of(Ledger::Accounts.seller(order.seller_id))).to eq(4_750)
    end
  end

  describe "refunding" do
    before { Ledger::CapturePayment.call(order: order, idempotency_key: "pay-1") }

    it "returns the full amount to the buyer and takes no fee" do
      Ledger::Refund.call(order: order, idempotency_key: "refund-1")

      expect(escrow_balance).to eq(0)
      expect(LedgerEntry.balance_of(Ledger::Accounts.buyer(order.buyer_id))).to eq(0)
      expect(LedgerEntry.balance_of(Ledger::Accounts::PLATFORM_FEE)).to eq(0)
    end
  end

  describe "the core invariant" do
    it "keeps every transaction balanced" do
      Ledger::CapturePayment.call(order: order, idempotency_key: "pay-1")
      Ledger::ReleasePayout.call(order: order, idempotency_key: "payout-1")

      LedgerTransaction.find_each do |transaction|
        expect(transaction).to be_balanced
      end
    end
  end
end
