namespace :effective_qb_online do

  # bundle exec rake effective_qb_online:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

end
