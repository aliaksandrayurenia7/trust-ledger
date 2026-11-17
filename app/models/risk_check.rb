class RiskCheck < ApplicationRecord
  belongs_to :order

  validates :rule_code, presence: true
  validates :points, numericality: { greater_than: 0 }
end
