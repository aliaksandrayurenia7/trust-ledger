class User < ApplicationRecord
  ROLES = %w[buyer seller support system].freeze

  # Generated on create, unique in the database, never guessable.
  has_secure_token :api_token, length: 32

  has_many :bought_orders, class_name: "Order", foreign_key: :buyer_id,  inverse_of: :buyer
  has_many :sold_orders,   class_name: "Order", foreign_key: :seller_id, inverse_of: :seller

  validates :role, inclusion: { in: ROLES }

  def support? = role == "support"
  def system?  = role == "system"
end
