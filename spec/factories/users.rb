FactoryBot.define do
  factory :user do
    role { "buyer" }
    country { "LT" }

    factory :seller do
      role { "seller" }
    end

    factory :support do
      role { "support" }
    end
  end
end
