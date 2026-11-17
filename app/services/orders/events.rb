module Orders
  # Every state change is appended here. Nothing is ever updated or deleted.
  module Events
    def self.record(order, to_state:, actor_type:, from_state: nil, actor_id: nil, reason_code: nil, note: nil)
      order.events.create!(
        from_state: from_state,
        to_state: to_state,
        actor_type: actor_type,
        actor_id: actor_id,
        reason_code: reason_code,
        note: note
      )
    end
  end
end
