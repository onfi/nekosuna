require 'sinatra'
require "json"
require 'open3'

PATH_CPP = File.expand_path('../tmp/Main.cpp', __FILE__)
PATH_OUT = File.expand_path('../tmp/a.out', __FILE__)

def json(stdout, stderr, status)
  {
    'STDOUT' => stdout,
    'STDERR' => stderr,
    'STATUS' => status 
  }.to_json
end

set :environment, :production
get '/' do
  erb :index
end

post '/build' do
  content_type :json
  File.open(PATH_CPP, 'w') do |f|
      f.puts(params['src'])
  end
  stdout, stderr, status = Open3.capture3("zapcc++ -std=c++14 -O2 -o #{PATH_OUT} #{PATH_CPP}")
  json(stdout,stderr,status)
end

post '/exec' do
  stdout, stderr, status = Open3.capture3(PATH_OUT, stdin_data: params['stdin'])
  json(stdout,stderr,status)
end