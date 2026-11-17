# Money model

Balances are never stored in a column. They are summed from `ledger_entries`,
and every transaction must sum to zero.

```mermaid
sequenceDiagram
    autonumber
    participant B as Buyer
    participant A as API
    participant L as Ledger
    participant S as Seller

    B->>A: POST /orders/1/payment (Idempotency-Key)
    A->>L: payment_captured
    Note over L: buyer -50.00<br/>escrow +50.00<br/>sum = 0

    B->>A: POST /orders/1/payment (same key)
    A-->>B: same result, no second transaction

    A->>A: delivery confirmed
    A->>L: payout_released
    Note over L: escrow -50.00<br/>seller +47.50<br/>platform +2.50<br/>sum = 0
    L-->>S: 47.50
```

An unbalanced set of entries raises before anything is written, so a partial
transaction can never exist.
