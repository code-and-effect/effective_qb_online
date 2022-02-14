require 'effective_resources'
require 'effective_datatables'
require 'effective_qb_online/engine'
require 'effective_qb_online/version'

module EffectiveQbOnline

  def self.config_keys
    [
      :layout
    ]
  end

  include EffectiveGem

end
