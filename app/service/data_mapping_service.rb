class DataMappingService
  def initialize(params)
    @params = params
  end

  def map
    eval(resolved_params)
  end

  private
  def resolved_params
    Setting.enum_permit.send(@params)
  end
end
