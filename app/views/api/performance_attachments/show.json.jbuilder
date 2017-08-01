json.attachments @attachments do |attachment|
  json.id attachment.id
  json.name attachment.file_name
  json.type attachment.file_type
  json.size attachment.file_size
  json.employee_id attachment.employee_id
  json.default Setting.upload_url + attachment.file.url
end
