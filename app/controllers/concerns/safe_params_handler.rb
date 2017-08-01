module SafeParamsHandler
  extend ActiveSupport::Concern

  def safe_params(safe_attributes)
    safe_attributes.each do |key|
      key_str = key.instance_of?(Hash) ? key.keys.first.to_s : key.to_s

      case key_str
      #when /_id$/
        #key_strip = key_str.sub(/_id$/, '')
        #params[key_str] = params[key_strip]["id"] if params[key_strip]
      when /_attributes$/
        key_strip = key_str.sub(/_attributes/, '')
        params[key_str] = params[key_strip]
      end
    end

    params.permit(*safe_attributes)
  end
end
