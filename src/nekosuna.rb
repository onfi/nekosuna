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
  `rm -rf #{path(params['id'])}`
  `mkdir -p #{path(params['id'])}`
  case params['src'].split(/\r?\n/).find{|s| !s.strip.empty?}
  when /\Aimport|input\(\)/
    File.open(path_py(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    json("","",0)
  when /gets/
    File.open(path_rb(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    json("","",0)
  else
    File.open(path_cpp(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    stdout, stderr, status = Open3.capture3("zapcc++ -std=c++17 -O2 -I/opt/boost/include -I/root/ac-library -L/opt/boost/lib -o #{path_out(params['id'])} #{path_cpp(params['id'])}")
    json(stdout,stderr,status)
  end
end

post '/exec' do
  if FileTest.exist?(path_py(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 python3 ' + path_py(params['id']), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  elsif FileTest.exist?(path_rb(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 ruby ' + path_rb(params['id']), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  elsif FileTest.exist?(path_out(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 ' + path_out(params['id']), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  end
end

def path(id) 
  File.expand_path("../tmp/#{id}/", __FILE__)
end

def path_cpp(id)
  File.expand_path("../tmp/#{id}/Main.cpp", __FILE__)
end

def path_py(id)
  File.expand_path("../tmp/#{id}/main.py", __FILE__)
end

def path_rb(id)
  File.expand_path("../tmp/#{id}/main.rb", __FILE__)
end

def path_out(id)
  File.expand_path("../tmp/#{id}/a.out", __FILE__)
end