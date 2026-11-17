module Risk
  module Rules
    class NewAccountHighValue < Base
      POINTS = 40
      def self.points = POINTS

      def applies?
        order.seller.created_at > 7.days.ago && order.amount_cents > 4_000
      end

      def details
        { seller_age_days: ((Time.current - order.seller.created_at) / 1.day).round }
      end
    end
  end
end
