# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

enable :sessions


class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true
end

helpers do
  def title
    if @title
      "#{@title}"
    else
      "Welcome."
    end
  end
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

# for Authentication
helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Invalid Credentials\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end

# get ALL posts
get "/" do
  @posts = Post.order("created_at DESC")
  @title = "Welcome."
  erb :"posts/index"
end

# create new post
get "/posts/create" do
  protected!
  @title = "Create post"
  @post = Post.new
  erb :"posts/create"
end
post "/posts" do
  @post = Post.new(params[:post])
  if @post.save
    redirect "posts/#{@post.id}", :notice => 'Post successful. (This message will disapear in 4 seconds.)'
  else
    redirect "posts/create", :error => 'Post unsuccessful. Try again. (This message will disapear in 4 seconds.)'
  end
end

# view post
get "/posts/:id" do
  @post = Post.find(params[:id])
  @title = @post.title
  erb :"posts/view"
end

# edit post
get "/posts/:id/edit" do
  protected!
  @post = Post.find(params[:id])
  @title = "Edit Form"
  erb :"posts/edit"
end
put "/posts/:id" do
  @post = Post.find(params[:id])
  @post.update(params[:post])
  redirect "/posts/#{@post.id}"
end

# delete post

post "/posts/:id/delete" do
  protected!
  @post = Post.find(params[:id]).destroy
  redirect "/"
end
