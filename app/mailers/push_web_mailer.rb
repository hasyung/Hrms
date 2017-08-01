class PushWebMailer < ApplicationMailer

  def send_email(to,subject,body)
    m =  mail to: to, subject: subject ,delivery_method: :smtp ,body: body ,from: "pbdpms@vip.qq.com"
  end
end
