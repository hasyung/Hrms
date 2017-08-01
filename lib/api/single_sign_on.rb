require 'savon'
require 'rexml/document'

module Api
  class SingleSignOn

    class << self
      def valid_trust_code(employee_no)
        response = nil
        begin
          client = Savon.client(wsdl: Setting.valid_trust_code, open_timeout: 3, read_timeout: 3)
          # client.operations
          response = client.call(:valid_trust_code, message: { empNo: employee_no, systemName: Setting.singpoint_sys_name })
          doc = Hash.from_xml(response.body[:valid_trust_code_response][:valid_trust_code_return])

          if(doc["root"]["code"] == "0")
            return [true, doc["root"]["trustCode"].to_s.strip]
          else
            return [false, doc["root"]["description"]]
          end
        rescue
          Rails.logger.error("单点登录系统连接超时")
          Rails.logger.error("response: #{response}")
          return [false, "单点登录系统连接超时"]
        end
      end

      def valid_effect_user(employee_no, password)
        response = nil
        begin
          client = Savon.client(wsdl: Setting.vaild_effect_user, open_timeout: 3, read_timeout: 3)
          response = client.call(:validator_legal_user, message: { empNo: employee_no, password: password })
          doc = Hash.from_xml(response.body[:validator_legal_user_response][:validator_legal_user_return])

          if(doc["root"]["code"] == "0")
            return nil
          else
            return doc["root"]["description"]
          end
        rescue
          Rails.logger.error("单点登录系统连接超时")
          Rails.logger.error("response: #{response}")
          "单点登录系统连接超时"
        end
      end
    end

  end
end
