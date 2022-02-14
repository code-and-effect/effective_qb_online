module EffectiveQbOnline
  class Engine < ::Rails::Engine
    engine_name 'effective_qb_online'

    # Set up our default configuration options.
    initializer 'effective_qb_online.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_qb_online.rb")
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_qb_online.active_record' do |app|
      ActiveSupport.on_load :active_record do
      end
    end

  end
end
