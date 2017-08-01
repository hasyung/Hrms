class Admin::ExternalApplicationsController < AdminController
  before_action :set_external_application, only: [:show, :edit, :update, :destroy]

  def index
    @externals = ExternalApplication.all
  end

  def show
  end

  # 辅助调试界面
  def debug
    @external = ExternalApplication.find params[:id]
    @time = Time.now.to_i + 300
    @signature_1 = Digest::MD5.hexdigest(URI::encode(["callNameDEPARTMENT", "apiKey#{@external.api_key}",
      "requestTime#{@time}", "version1", "count10", "lastId1", "fetchAll0"].sort.join('')) + @external.api_secret)
    @signature_2 = Digest::MD5.hexdigest(URI::encode(["callNameEMPLOYEE", "apiKey#{@external.api_key}",
      "requestTime#{@time}", "version1", "count10", "lastId1", "fetchAll0"].sort.join('')) + @external.api_secret)
    @signature_3 = Digest::MD5.hexdigest(URI::encode(["callNameCHANGE_RECORD", "apiKey#{@external.api_key}",
      "requestTime#{@time}", "version1", "count10", "lastId1", "fetchAll0"].sort.join('')) + @external.api_secret)
    @signature_4 = Digest::MD5.hexdigest(URI::encode(["callNameUPDATE_PHONE", "apiKey#{@external.api_key}",
      "requestTime#{@time}", "version1", "employeeNo003740", "telephone110", "mobile120"].sort.join('')) + @external.api_secret)
    @signature_5 = Digest::MD5.hexdigest(URI::encode(["callNamePERFORMANCE", "apiKey#{@external.api_key}",
                                                      "requestTime#{@time}", "version1", "employeeNo003740", "count10", "lastId1"].sort.join('')) + @external.api_secret)
    if @external.push_type == 1
      render template: 'admin/external_applications/send_push'
    end

  end

  # 计算签名
  def calc_signature
    @external = ExternalApplication.find_by(api_key: params[:apiKey])
    permit_params = params.permit(:apiKey, :version, :callName, :requestTime,
      :count, :lastId, :fetchAll, :orgNumber, :changeType, :startTime, :endTime, :employeeNo,:year,:category)
    suc_params = permit_params.inject([]){|arr, val|arr << val[0].to_s + val[1].to_s}.sort.join('')
    message = ["1. 字典排序(参数名称&参数的值)并连接: #{suc_params}<br>"]
    success_param = URI::encode(suc_params) + @external.api_secret
    message << "2. 对连接后的参数进行URL编码，再加上api_secret: #{success_param}<br>"
    @api_result = Digest::MD5.hexdigest(success_param)
    message << "3. 最后进行md5哈希摘要运算"

    render json: {"签名" => @api_result, "计算过程" => message}
  end

  # 推送数据，发送 http 请求到推送地址
  def send_push
    @external = ExternalApplication.find params[:id]
  end

  def new
    @external = ExternalApplication.new(
      api_key: SecureRandom.hex(16),
      api_secret: SecureRandom.hex(32),
      company_name: '四川航空',
      client_ips: []
    )
  end

  def create
    data = limit_params
    data[:client_ips] = data.delete(:client_ips).to_s.split(/,/)
    @external = ExternalApplication.create(data)

    if @external.save
      render action: "show"
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    data = limit_params
    data[:client_ips] = data.delete(:client_ips).to_s.split(",")

    if @external.update(data)
      render action: 'show'
    else
      render action: 'edit'
    end
  end

  def destroy
    if @external.destroy
      flash[:notice] = '删除成功'
    else
      flash[:error] = '删除失败'
    end

    redirect_to admin_external_applications_path
  end

  private
  def limit_params
    params.require(:external_application).permit(:application_name, :company_name, :api_key, :api_secret, :push_url, :description, :client_ips, :check_ip, :check_signature, :check_time, :push_retry_count,:push_type,:email)
  end

  def set_external_application
    @external = ExternalApplication.find params[:id]
  end
end