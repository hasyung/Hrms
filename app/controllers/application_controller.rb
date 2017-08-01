class ApplicationController < ActionController::Base
  include SafeParamsHandler

  # protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :current_employee
  before_action :load_controller_action, except: [:conditions] unless Rails.env.test?
  before_action :check_action_register, except: [:conditions] unless Rails.env.test?
  before_action :check_permission, except: [:conditions] unless Rails.env.test?
  after_action :record_log, except: [:conditions] if Rails.env.production?
  after_action :allow_iframe
  after_action :set_cors

  def current_employee
    @current_employee = AuthenticateToken.authorize!(access_token)
  end

  def check_action_register
    unless @permission.present?
      logger.error "#{@controller}##{@action} should be register firstly"
      render json: {messages: 'action_unregister'}, status: 403
    end
  end

  def check_permission
    @ca_hash = {
      "contracts" => "create",
      "contracts" => "update",
      "contracts" => "import",
      "agreements" => "create",
      "agreements" => "update",
    }

    @ca_hash.each do |c, a|
      sp = Permission.find_by(controller: c, action: a)

      if sp
        array = current_employee.special_ca

        if current_employee.has_permission?(current_employee.employee_bits, sp)
          array << "#{c}_#{a}"
        else
          array.delete("#{c}_#{a}")
        end

        current_employee.update!(special_ca: array.uniq)
      end
    end

    unless current_employee.has_permission?(current_employee.employee_bits, @permission)
      # 更多的用于测试手段，因为前段已经根据权限进行了UI控制
      render json: {messages: 'no_permission', controller: @controller, action: @action}, status: 403
    end
  end

  def record_log
    data = params.deep_dup
    [:controller, :action].each { |x| data.delete(x) }
    data[:user].delete(:password) if data[:user]

    if current_employee
      hash = {
        employee_no: current_employee.id,
        employee_name: current_employee.name,
        permission_message: "#{params[:controller]}_#{params[:action]}",
      }
    else
      hash = {
        permission_message: "#{params[:controller]}_#{params[:action]}",
        params: data
      }
    end

    hash.merge!({
      params: data,
      message: @message,
      request_ip: request.remote_ip,
      response_status: response.status,
      permission_message: @permission.name
    }) if @permission

    Log.create(hash)
  end

  private

  def authenticate_user!
    if !current_employee
      render json: {messages: '继续操作前请先登陆!'}, status: :unauthorized
    else
      logger.info "#{current_employee.id} - #{current_employee.name} - #{current_employee.employee_no} 来自 #{request.remote_ip}"
    end
  end

  def access_token
    cookies['token']
  end

  def load_controller_action
    @controller = params[:controller].gsub(/api\//, "")
    @action = params[:action]
    @condition = {controller: @controller, action: @action}
    @permission = Permission.where(@condition).first
  end

  def parse_query_params!(zlass)
    query_params = params.deep_dup
    query_params = query_params.delete_if{|p| p["format"] || p["controller"] || p["action"]}
    page_params = {page: query_params.delete("page"), per_page: query_params.delete("per_page")}

    if query_params["sort"].present? && query_params["order"].present?
      sort_params = {query_params.delete("sort") => query_params.delete("order")}
    end

    conditions, relations, sorts, page = [], [], '', {}
    position_options = QuerySetting[zlass]

    if query_params.present?
      query_params.each do |key, value|
        position_field = position_options[key]
        next if position_field.blank?

        if position_field['type'].include?('-')
          outer_type, inner_type = position_field['type'].split('-')

          if outer_type == 'Array'
            if key == 'position_names'
              query_condition =
                value.inject("") do |query_conditions, name|
                  query_conditions << position_field['sql'].sub('?', "'%#{name}%' OR ")
                  query_conditions
                end
              (conditions << query_condition.sub(/\sOR\s$/, ''))
            else
              value = Department.get_self_and_childrens(value) if key == 'department_ids'
              conditions << [position_field['sql'], value]
            end
          elsif outer_type == 'Range'
            value['from'] ||= default_value(inner_type, "from")
            value['to'] ||= default_value(inner_type, "to")
            conditions << [position_field['sql'], value['from'], value['to']]
          end
        else
          conditions << parse_normal(position_field, value)
        end

        relations << position_field['relation']
      end
    end

    if sort_params.present?
      sort_params.each do |key, value|
        return {error: "[sort] #{key} 类型错误!"} unless ["ASC", "DESC"].include?(value.upcase)
        sql = position_options[key]['sort']
        next if sql.blank?
        str = sql + ' ' + value.upcase
        sorts = sorts.blank? ? str : "#{sorts}, #{str}"
      end
    end

    str = QuerySetting['default']['sort']
    sorts = sorts.blank? ? str : "#{sorts}, #{str}"

    page[:page] = page_params.extract(:page, QuerySetting['default']['page'])
    page[:per_page] = page_params.extract(:per_page, QuerySetting['default']['per_page'])

    {relations: relations.compact.uniq.map(&:to_sym), conditions: conditions, sorts: sorts, page: page}
  end

  def set_page_meta(model, page)
    @count = model.size

    if page[:page].present? && page[:per_page].present?
      model = model.paginate(page)
      @page, @per_page, @total_pages = page[:page].to_i, page[:per_page].to_i, model.total_pages
    end

    model
  end

  private
  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def set_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def default_value(inner_type, prefix)
    hash = {
      "from_Date" => "date_from",
      "from_Integer" => "int_from",
      "to_Date" => Date.current + 60.year,
      "to_Integer" => "int_to"
    }
    "#{prefix}_#{inner_type}" == "to_Date" ? hash["#{prefix}_#{inner_type}"] : QuerySetting['default'][hash["#{prefix}_#{inner_type}"]]
  end

  def parse_normal(position_field, value)
    case position_field['query_type']
    when 'Like'
      return [position_field['sql'], "%#{value}%"]
    when 'Boolean'
      return [position_field["sql_#{value}"]]
    when 'Integer'
      return [position_field['sql'], value.to_i]
    when 'String_Equal'
      return [position_field['sql'], value, value]
    else
      return [position_field['sql'], value]
    end
  end
end
