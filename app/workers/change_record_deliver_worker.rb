class ChangeRecordDeliverWorker
  include Sidekiq::Worker

  def perform(change_record_id, ids = nil)
    logger.error "#{change_record_id} in push"
    change_record = ChangeRecord.find_by(id: change_record_id)
    logger.error change_record.to_s

    if change_record && !(change_record.is_pushed)
      serialized_data = {
        changeType: change_record.change_type,
        eventTime:  change_record.event_time.to_i,
        changeData: change_record.change_data
      }

      if ids.present?
        externals = ExternalApplication.where(id: ids)
      else
        externals = ExternalApplication.all
      end

      externals.each do |external|
        next if external.push_type.to_i == 1
        next if external.push_url.blank?
        repeat = 0

        logger.info "=====异动类型: #{change_record.change_type}, 异动ID: #{change_record.id} 开始执行====="

        while repeat <= external.push_retry_count.to_i
          begin
            sleep rand(10)
            response = RestClient.post(external.push_url, {data: serialized_data}.to_json, content_type: :json, accept: :json)
            logger.error "URL: #{external.push_url} response code: #{response.code}"
            logger.error "response_code: #{response.code}"
            logger.error "response: #{response.to_str}"

            if response.code == 200
              logger.error "推送成功"

              ok_array = change_record.ok_array || []
              ok_array << external.id

              change_record.update_columns(
                ok_array: ok_array.uniq,
                is_pushed: true
              )

              @admin_emp = Employee.unscoped.find_by(name: "administrator")
              if @admin_emp.present?
                hash = {
                  employee_no:        @admin_emp.id,
                  employee_name:      @admin_emp.name,
                  permission_message: "push #{external.application_name}",
                  params:             serialized_data.to_json,
                  request_ip:         external.push_url,
                  message:            "successed"
                }
                Log.create(hash)
              end
              break
            else
              logger.error "推送失败"

              failed_array = change_record.failed_array || []
              failed_array << external.id

              change_record.update_columns(
                failed_array: failed_array.uniq,
              )

              @admin_emp = Employee.unscoped.find_by(name: "administrator")
              if @admin_emp.present?
                hash = {
                  employee_no:        @admin_emp.id,
                  employee_name:      @admin_emp.name,
                  permission_message: "push #{external.application_name}",
                  params:             serialized_data.to_json,
                  request_ip:         external.push_url,
                  message:            "failed"
                }
                Log.create(hash)
              end
            end
          rescue Exception => ex
            logger.error "推送异常"
            logger.error "URL: #{external.push_url}"
            logger.error "Exception: #{ex.to_s}"

            failed_array = change_record.failed_array || []
            failed_array << external.id

            change_record.update_columns(
              failed_array: failed_array.uniq,
            )

            @admin_emp = Employee.unscoped.find_by(name: "administrator")
            if @admin_emp.present?
              hash = {
                employee_no:        @admin_emp.id,
                employee_name:      @admin_emp.name,
                permission_message: "push #{external.application_name}",
                params:             serialized_data.to_json,
                request_ip:         external.push_url,
                message:            "failed"
              }
              Log.create(hash)
            end
          ensure
            repeat += 1
          end
        end
      end
    end
  end
end
