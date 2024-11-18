# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    association :sender, factory: :user
    association :sender_wallet, factory: :wallet
    association :recipient_wallet, factory: :wallet
    amount { 100.0 }
    currency { 'USD' }
    transaction_type { 'immediate' }
    status { 'pending' }

    trait :scheduled do
      transaction_type { 'scheduled' }
      execution_date { 1.day.from_now }
    end

    trait :processing do
      status { 'processing' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :canceled do
      status { 'canceled' }
    end

    trait :failed do
      status { 'failed' }
    end
  end
end
