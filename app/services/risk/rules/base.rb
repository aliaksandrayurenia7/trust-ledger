module Risk
  module Rules
    # Every rule answers one question about an order and is worth some points.
    class Base
      def self.code = name.demodulize.underscore
      def self.points = raise(NotImplementedError)

      def initialize(order) = @order = order
      def applies? = raise(NotImplementedError)
      def details = {}

      attr_reader :order
    end
  end
end
