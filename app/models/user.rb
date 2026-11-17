class User < ApplicationRecord
  ROLES = %w[buyer seller support].freeze

  has_many :bought_orders, class_name: "Order", foreign_key: :buyer_id,  inverse_of: :buyer
  has_many :sold_orders,   class_name: "Order", foreign_key: :seller_id, inverse_of: :seller

  validates :role, inclusion: { in: ROLES }
end
