json.array!(@response.files) do |file|
  json.id file.id
  json.text file.name.tr('/', '-').tr(':', '-') # replace any "/"s or ":"s in file names with "-" because they're illegal
  json.parent @parent_folder == 'root' ? '#' : @parent_folder
  json.icon file.icon_link
  json.children file.mime_type === 'application/vnd.google-apps.folder' ? true : false
  json.data Hash['mime_type', file.mime_type]
end
