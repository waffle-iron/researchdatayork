class GoogledriveController < ApplicationController

  include Googledrive

  # connect to the Google API and begin the process of autheticating
  def connect
    # if we're already connected to the API
    if connected_to_google_api? 
      # just redirect straight to the finish
      redirect_to finish_googledrive_index_url
    # otherwise, create a new oauth2 client and redirect to Google's authorisation page
    else
      client = oauth2client
      redirect_to client.authorization_uri(:approval_prompt => "force").to_s
    end
  end

  # handle the callback from Google (it will respond to the above call) and grab the authorisation code
  def oauth2callback
    client = oauth2client
    # update the oauth2 client with the authorisation code that Google just gave us
    client.update!(:code => params[:code])
    # get the access and refresh tokens
    response = client.fetch_access_token!
    # persist the refresh tokens - it can be used to obtain access_tokens in future
    session[:refresh_token] = response['refresh_token']
    redirect_to finish_googledrive_index_url
  end 

  # finish off the connection process
  def finish
    respond_to do |format|
      format.html { render :finish, :layout => false }
    end
  end

  # get a list of the user's google drive files in a specified folder (default to "root") and respond with json
  def index
    # default folder to search is the "root" folder
    @parent_folder = "root"
    # if given a folder param, use that
    if params[:folder]
      @parent_folder = params[:folder]
    end
    @response = list_files_in_folder(@parent_folder)
    respond_to do |format|
      format.json { render :index }
    end
  end

end
