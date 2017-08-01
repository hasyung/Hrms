json.performances @performances do |performance|
    json.id                   performance[:id]
    json.employee_name        performance[:employee].name
    json.employee_id          performance[:employee].id
    json.employee_no          performance[:employee].employee_no
    json.position_name        performance[:employee].master_position.try(:name)
    json.department_name      performance[:employee].department.full_name
    json.channel              performance[:employee].channel.try(:display_name)
    json.sort_no              performance[:sort_no]
    json.january              performance[:january]
    json.february             performance[:february]
    json.march                performance[:march]
    json.april                performance[:april]
    json.may                  performance[:may]
    json.june                 performance[:june]
    json.july                 performance[:july]
    json.august               performance[:august]
    json.september            performance[:september]
    json.october              performance[:october]
    json.november             performance[:november]
    json.december             performance[:december]
    json.season               performance[:season]
    json.year                 performance[:year]

end



json.partial! 'shared/page_basic'
