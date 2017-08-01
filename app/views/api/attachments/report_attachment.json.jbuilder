json.attachment do
  json.id @attachment.id
  json.name @attachment.file_name
  json.type @attachment.file_type
  json.size @attachment.file_size
  json.default Setting.upload_url + @attachment.file.url

  if @attachment.file_type.include?("image/")
    json.thumb Setting.upload_url + @attachment.file.url
  end
end

