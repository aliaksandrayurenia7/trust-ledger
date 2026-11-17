class OrderEvent < ApplicationRecord
  ACTOR_TYPES = %w[system support buyer seller].freeze

  belongs_to :order

  validates :to_state, presence: true
  validates :actor_type, inclusion: { in: ACTOR_TYPES }

  # this table is append only, it has created_at but no updated_at
  self.record_timestamps = true
end
