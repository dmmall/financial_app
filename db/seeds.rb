# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

user = User.create!(email: 'test@example.com')
user2 = User.create!(email: 'test2@example.com')
user3 = User.create!(email: 'test3@example.com')
user4 = User.create!(email: 'test4@example.com')

user.wallets.create!(currency: :USD, balance: 1000, active: true)
user2.wallets.create!(currency: :USD, balance: 1000, active: true)
user3.wallets.create!(currency: :USD, balance: 1000, active: true)
user4.wallets.create!(currency: :USD, balance: 1000, active: true)


user.wallets.create!(currency: :EUR, balance: 1000, active: true)
user2.wallets.create!(currency: :EUR, balance: 1000, active: true)
user3.wallets.create!(currency: :EUR, balance: 1000, active: true)
user4.wallets.create!(currency: :EUR, balance: 1000, active: true)


