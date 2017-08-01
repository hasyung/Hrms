module Connectable
  extend ActiveSupport::Concern

  included do
    self.send :include, MasterSlave::Core
  end

  module ClassMethods
    def connect_history_db(load_version, &block)
      MasterSlave.setup!(load_version)

      slave_name = "history_#{load_version}"
      ActiveRecord::Base.using(slave_name.to_sym) do
        block.call
      end
    end
  end
end
