module FlowSafeAttributes
  extend ActiveSupport::Concern

  included do
    def safe_flow_attributes(flow_type)
      flow_config = FlowSetting.to_hash[flow_type]
      flow_config ? flow_config['params'] : []
    end
  end
end
