require 'sinatra'
require "json"
require 'open3'
require 'securerandom'

def json(stdout, stderr, status)
  {
    'STDOUT' => stdout,
    'STDERR' => stderr,
    'STATUS' => status 
  }.to_json
end

set :environment, :production
get '/' do
  @id = SecureRandom.uuid
  erb :index
end

post '/build' do
  content_type :json
  `mkdir -p #{path(params['id'])}`
  File.open(path_cpp(params['id']), 'w') do |f|
      f.puts(params['src'])
  end
  stdout, stderr, status = Open3.capture3("zapcc++ -std=c++17 -O2 -I/opt/boost/include -L/opt/boost/lib -o #{path_out(params['id'])} #{path_cpp(params['id'])}")
  json(stdout,stderr,status)
end

post '/exec' do
  stdout, stderr, status = Open3.capture3('timeout -sKILL 5 ' + path_out(params['id']), stdin_data: params['stdin'])
  json(stdout[0..10000],stderr,status)
end

def path(id) 
  File.expand_path("../tmp/#{id}/", __FILE__)
end

def path_cpp(id)
  File.expand_path("../tmp/#{id}/Main.cpp", __FILE__)
end

def path_out(id)
  File.expand_path("../tmp/#{id}/a.out", __FILE__)
end