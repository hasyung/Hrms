require 'savon'
class ChangeRecordDeliverWebWorker
  include Sidekiq::Worker


  def perform(change_record_web_ids, ids = nil,debug = false)

    logger.error "#{change_record_web_ids} in web push"


    change_record_webs = ChangeRecordWeb.where(id: change_record_web_ids)

    if change_record_webs.blank?
      return
    end
    externals = nil
    if ids == nil
      externals = ExternalApplication.where(push_type: 1).order('id')
    else
      externals = ExternalApplication.where(id: ids).order(id)
    end

    employees = [:psn_synch,:psn_synch_response,:return]
    postions = [:post_sync,:post_sync_response,:return]
    funcs = {

        'employee_create' =>employees,
        'employee_update' =>employees,
        'employee_dimission'=>employees,
        'employee_special'=> employees,
        'position_create'=>postions,
        'position_update'=>postions,
        'position_destroy'=>postions
    }

    opercodes ={
        'employee_create'=>'0',
        'employee_update' =>'1',
        'employee_dimission'=>'2',
        'employee_special'=>'3',
        'position_create'=>'0',
        'position_update'=>'1',
        'position_destroy' =>'2'
    }

    send_arry = []
    change_record_webs.each do |change_record_web|

      if debug == false && change_record_web.is_pushed
        logger.info "人力系统推送 #{change_record_web.id} 已经进行过推送 并且不是调试模式"
        next
      end
      save_data = { string: change_record_web.change_data.to_json, string1: opercodes[change_record_web.change_type]}
      json_msg = nil
      success = false
      count = externals.count > 2 ? 2 : externals.count
      nowcount = 0
      externals.each do |external|

        nowcount += 1
        if external.push_type != 1 then # 不属于当前的推送类型
          success = true
          logger.error "#{external.id} in not web push"
          next
        end
        logger.info "人力系统推送=====异动类型: #{change_record_web.change_type}, 异动ID: #{change_record_web.id} 开始执行====="

        reapt = 0
        reaptcount = external.push_retry_count.present? ? external.push_retry_count.to_i : 5

        if reaptcount < 1 then #保证至少执行一次
          reaptcount = 1
        end

        while reapt < reaptcount
          begin
            message = { string: change_record_web.change_data.to_json, string1: opercodes[change_record_web.change_type]}
            funcinfo = funcs[change_record_web.change_type]
            client = Savon.client(wsdl: external.push_url)
            client.operations
            response = client.call(funcinfo[0], message: message)

            logger.error "URL: #{external.push_url + change_record_web.change_type}"
            logger.error "success: #{response.success?}"
            logger.error "response: #{response.body}"

            json_msg =  JSON.parse  response.body[funcinfo[1]][funcinfo[2]]


            if json_msg.blank?
              logger.error "can't parse json msg #{response.body}"
              save_log("push_web#{external.application_name}",
                       save_data.to_json,external.push_url + change_record_web.change_type,
                       [state:-2 , msg:"can't parse json #{response.body}"])
              reapt += 1
              next
            end

            if json_msg["state"].blank? || json_msg["state"].to_i != 0

              logger.error "对方处理失败#{response.body}"
              save_log("push_web#{external.application_name}",

                       save_data.to_json,external.push_url + change_record_web.change_type,

                       response.body)
              reapt +=1
              next
            end
            success = true
            break
          rescue Exception => ex
            reapt +=1
            logger.error "推送异常"

            logger.error "URL: #{external.push_url }"
            logger.error "Exception: #{ex.to_s}"

            save_log("push_web#{external.application_name}",
                     save_data.to_json,external.push_url + change_record_web.change_type,


                     [code:-1,msg: ex.to_s])
            json_msg = {'msg' => ex.to_s , "state" => -1}
          end #begin end
        end #while end
        if success
          logger.info "推送成功"
          ok_array = change_record_web.ok_array || []
          ok_array << external.id
          change_record_web.update(
              ok_array: ok_array.uniq,
              is_pushed: true,
              code:      json_msg['state'],
              msg:       json_msg['msg']
          )
          save_log("push_web#{external.application_name}",
                   save_data.to_json,external.push_url + change_record_web.change_type,json_msg.to_json)

          break
        else
          if nowcount >= count
            send_arry << [save_data.to_json,json_msg.to_json,external.email]
            failed_array = change_record_web.failed_array || []
            failed_array << external.id
            change_record_web.update(
                failed_array: failed_array.uniq,
                is_pushed: true,
                code:      json_msg['state'],
                msg:       json_msg['msg']
            )
            break
          end
        end

      end # externals end
    end #change_record_webs end

    send_arry.each do |info|
      send_email(info[0],info[1],info[2])
    end
  end

  private
  def save_log(permission_message,params,request_ip,message)
    @admin_emp = Employee.unscoped.find_by(name: "administrator")
    if @admin_emp.present?
      hash = {
          employee_no:        @admin_emp.id,
          employee_name:      @admin_emp.name,
          permission_message: permission_message,
          params:             params,
          request_ip:         request_ip,
          message:            message
      }

      Log.create(hash)
    end
  end

  def send_email(params,message,email)
    hash = {
        params:             params,
        message:            message
    }
    PushWebMailer.send_email(email,"错误报告",hash.to_json).deliver_now
  end
end
