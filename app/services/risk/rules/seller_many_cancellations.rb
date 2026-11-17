module Risk
  module Rules
    class SellerManyCancellations < Base
      POINTS = 30
      def self.points = POINTS

      def applies?
        cancellations >= 3
      end

      def details = { cancellations_last_30_days: cancellations }

      private

      def cancellations
        @cancellations ||= Order
          .where(seller_id: order.seller_id, state: "refunded")
          .where(updated_at: 30.days.ago..)
          .count
      end
    end
  end
end
