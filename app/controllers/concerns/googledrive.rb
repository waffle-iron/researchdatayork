module Googledrive
  extend ActiveSupport::Concern

  require 'google/apis/drive_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  require 'fileutils'
    
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Research Data York Google Drive Browser'
  CLIENT_SECRETS_PATH = 'client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "drive-ruby-quickstart.yaml")
  #SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY
  #SCOPE = 'https://www.googleapis.com/auth/drive'
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_READONLY

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def initialise_api
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end 

  # given a google drive folder id, return the files in that folder
  def list_files_in_folder (folder)
    # Initialise the API
    service = initialise_api
    files = service.list_files(q: "'#{folder}' in parents and trashed=false", order_by: "folder,modifiedTime desc,name", 
                                   fields: "files(id, name, parents, iconLink, mimeType)")
    files
  end

  # given a google drive file id, download the file and return it
  def get_file_from_google (fileid, mime_type)
    file_contents = StringIO.new
    # initialise the api
    service = initialise_api
    # if the mime type for this file is a google document
    if mime_type.starts_with?("application/vnd.google-apps")
      # find a suitable export mime type according to table at https://developers.google.com/drive/v3/web/manage-downloads
      export_mime_type = ""
      case mime_type
      when /\.document$/
        export_mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      when /\.spreadsheet$/
        export_mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      when /\.drawing$/
        export_mime_type = "image/jpeg"
      when /\.presentation$/
        export_mime_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      when /\.script$/
        export_mime_type = "application/vnd.google-apps.script+json"
      end
      # export the file from google drive
      file = service.export_file(fileid, export_mime_type, download_dest: file_contents)
    # otherwise it's a "normal" file - just download it
    else
      file = service.get_file(fileid, download_dest: file_contents)
    end
    file_contents
  end
end