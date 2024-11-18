# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    association :user
    currency { 'USD' }
    balance { 1000.0 }
    active { true }

    trait :eur do
      currency { 'EUR' }
    end

    trait :inactive do
      active { false }
    end

    trait :empty do
      balance { 0 }
    end
  end
end
