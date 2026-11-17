# Order lifecycle

Money is held by the platform until delivery is confirmed. Every transition
below is appended to `order_events` with an actor and a reason code.

```mermaid
stateDiagram-v2
    direction LR

    [*] --> created
    created --> held: payment captured
    held --> under_review: risk score >= 70
    under_review --> held: support approves
    under_review --> refunded: support rejects
    held --> payout_ready: delivery confirmed
    held --> under_review: dispute opened
    payout_ready --> under_review: dispute opened
    payout_ready --> completed: payout released
    under_review --> completed: dispute resolved, seller wins
    under_review --> refunded: dispute resolved, buyer wins
    completed --> [*]
    refunded --> [*]
```

`completed` and `refunded` are final. The state machine refuses every other
transition, which is covered by specs in `spec/models/order_spec.rb`.
