module Ledger
  # Account names are strings, not rows. A balance is always computed
  # by summing entries, it is never stored in a column.
  module Accounts
    PLATFORM_FEE = "platform:fee".freeze

    def self.buyer(user_id)  = "buyer:#{user_id}"
    def self.seller(user_id) = "seller:#{user_id}"
    def self.escrow(order_id) = "escrow:order_#{order_id}"
  end
end
