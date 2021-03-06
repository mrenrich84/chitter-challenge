ENV["RACK_ENV"] ||= "development"
require 'sinatra/base'
require 'sinatra/flash'
require 'pry-byebug' if ENV["RACK_ENV"] == "development"

require_relative 'data_mapper_setup'
require_relative 'helpers'

class Chitter < Sinatra::Base
  enable :sessions
  set :session_secret, 'secret'
  register Sinatra::Flash
  use Rack::MethodOverride
  helpers ApplicationHelper

  get '/' do
    erb :index
  end

  get '/user/new' do
    @user = User.new # use this to enable field autocompletion in erb for failed attempts
    erb :'user/new'
  end

  post '/user/signing_up' do
    user = User.new(
      email: params[:email],
      password: params[:password],
      password_confirmation:  params[:password_confirmation],
      name:  params[:name],
      username:  params[:username])
    if user.save
      session[:user_id] = user.id
      redirect to('/')
    else
      flash.now[:notice] = user.errors.to_hash.map do |property, messages|
        messages.map do |message|
          "Problems with #{property}: #{message}"
        end
      end.join("<br>")
      erb :'user/new'
    end
  end

  get '/sessions/new' do
    erb :'sessions/new'
  end

  post '/sessions' do
    user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      redirect to('/')
    else
      flash.now[:errors] = ['The email or password is incorrect']
      erb :'sessions/new'
    end
  end

  delete '/sessions' do
    flash.keep[:notice] = "Goodbye #{current_user.username}!"
    session[:user_id] = nil
    redirect to '/'
  end

  post '/peep/new' do
    peep = Peep.new(message: params[:peep_new_message], user: current_user)
    peep.source = Peep.get(params[:source]) if params[:source]
    flash[:notice] = 'Cannot peep: some troubles while peeping!' unless peep.save
    redirect to('/')
  end

  #run! if app_file == $0
  run! if app_file == $0
end
