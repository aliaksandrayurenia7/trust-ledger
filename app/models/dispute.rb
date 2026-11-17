class Dispute < ApplicationRecord
  OPENED_BY   = %w[buyer seller].freeze
  STATES      = %w[open resolved].freeze
  RESOLUTIONS = %w[buyer_wins seller_wins].freeze

  belongs_to :order
  belongs_to :assigned_support, class_name: "User", optional: true

  validates :opened_by,  inclusion: { in: OPENED_BY }
  validates :state,      inclusion: { in: STATES }
  validates :resolution, inclusion: { in: RESOLUTIONS }, allow_nil: true
  validates :reason_code, presence: true

  scope :open, -> { where(state: "open") }
end
