json.reports @reports do |report|
  json.id            report.id
  json.title         report.title
  json.content       report.content
  json.checker       report.checker
  json.created_at    report.created_at
  json.reporter_name report.employee.name

  json.attachments report.attachments do |attachment|
    json.id attachment.id
    json.name attachment.file_name
    json.type attachment.file_type
    json.size attachment.file_size
    json.default Setting.upload_url + attachment.file.url

    if attachment.file_type.include?("image/")
      json.thumb Setting.upload_url + attachment.file.url
    end
  end
end
