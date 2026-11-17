FactoryBot.define do
  factory :order do
    association :buyer,  factory: :user
    association :seller, factory: :seller
    amount_cents { 5_000 }
    currency { "EUR" }
  end
end
