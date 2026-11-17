module Risk
  # Runs every rule against an order, stores what fired, and returns the score.
  # No machine learning: a human must be able to read the reason out loud.
  class Engine
    RULES = [
      Rules::NewAccountHighValue,
      Rules::SellerManyCancellations,
      Rules::HighValueOrder
    ].freeze

    MAX_SCORE = 100

    def self.call(order:) = new(order).call

    def initialize(order) = @order = order

    def call
      @order.risk_checks.destroy_all

      fired = RULES.map { |rule_class| rule_class.new(@order) }.select(&:applies?)

      fired.each do |rule|
        @order.risk_checks.create!(
          rule_code: rule.class.code,
          points: rule.class.points,
          details: rule.details
        )
      end

      score = [ fired.sum { |rule| rule.class.points }, MAX_SCORE ].min
      @order.update!(risk_score: score)
      score
    end
  end
end
