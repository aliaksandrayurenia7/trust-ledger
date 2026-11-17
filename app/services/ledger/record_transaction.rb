module Ledger
  # Writes one balanced transaction: a set of entries that sum to zero.
  # The same idempotency key never produces a second transaction.
  class RecordTransaction
    class UnbalancedError < StandardError; end

    def self.call(order:, kind:, idempotency_key:, entries:)
      new(order:, kind:, idempotency_key:, entries:).call
    end

    def initialize(order:, kind:, idempotency_key:, entries:)
      @order = order
      @kind = kind
      @idempotency_key = idempotency_key
      @entries = entries
    end

    def call
      raise UnbalancedError, "entries must sum to zero" unless balanced?

      existing = LedgerTransaction.find_by(idempotency_key: @idempotency_key)
      return existing if existing

      LedgerTransaction.transaction do
        transaction = LedgerTransaction.create!(
          order: @order,
          kind: @kind,
          idempotency_key: @idempotency_key
        )

        @entries.each do |entry|
          transaction.entries.create!(
            account: entry[:account],
            amount_cents: entry[:amount_cents]
          )
        end

        transaction
      end
    rescue ActiveRecord::RecordNotUnique
      # two requests arrived at the same moment, the other one won
      LedgerTransaction.find_by!(idempotency_key: @idempotency_key)
    end

    private

    def balanced?
      @entries.sum { |entry| entry[:amount_cents] }.zero?
    end
  end
end
