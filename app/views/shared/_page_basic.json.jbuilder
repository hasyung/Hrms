json.meta do
  if @total_pages
    json.pages_count @total_pages
    json.page @page
    json.per_page @per_page
    json.count @count
  end
end
