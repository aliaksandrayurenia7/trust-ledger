module Risk
  module Rules
    class HighValueOrder < Base
      POINTS = 25
      def self.points = POINTS

      def applies?
        order.amount_cents > 10_000
      end

      def details = { amount_cents: order.amount_cents }
    end
  end
end
