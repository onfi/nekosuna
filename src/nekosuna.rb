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
  when /package|java\.|system\.out/
    File.open(path_java(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    stdout, stderr, status = Open3.capture3("javac -encoding UTF-8 #{path_java(params['id'])}")
    json(stdout,stderr,status)
  when /\Aimport|input\(\)/
    File.open(path_py(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    json("","",0)
  when /fn |use [a-z]+::|-\*-/
    `cp -r --preserve=timestamps #{path_rust_template} #{path(params['id'])}`
    File.open(path_rust(params['id']), 'w') do |f|
      f.puts(params['src'])
    end
    stdout, stderr, status = Open3.capture3("cd #{path(params['id'])} && /root/.cargo/bin/cargo build --release --quiet")
    json(stdout,stderr,status)
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
  if FileTest.exist?(path_java_class(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 java -classpath ' + path(params['id'] + ' Main'), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  elsif FileTest.exist?(path_py(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 python3 ' + path_py(params['id']), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  elsif FileTest.exist?(path_rb(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 ruby ' + path_rb(params['id']), stdin_data: params['stdin'])
    json(stdout[0..10000],stderr,status)
  elsif FileTest.exist?(path_rust_main(params['id']))
    stdout, stderr, status = Open3.capture3('timeout -sKILL 5 ' + path_rust_main(params['id']), stdin_data: params['stdin'])
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

def path_java(id)
  File.expand_path("../tmp/#{id}/Main.java", __FILE__)
end

def path_java_class(id)
  File.expand_path("../tmp/#{id}/Main.class", __FILE__)
end

def path_rust(id)
  File.expand_path("../tmp/#{id}/src/main.rs", __FILE__)
end

def path_rust_template
  File.expand_path("../template/rust/*", __FILE__)
end

def path_rust_cargo(id)
  File.expand_path("../tmp/#{id}/Cargo.toml", __FILE__)
end

def path_rust_main(id)
  File.expand_path("../tmp/#{id}/target/release/main", __FILE__)
end

def path_rb(id)
  File.expand_path("../tmp/#{id}/main.rb", __FILE__)
end

def path_out(id)
  File.expand_path("../tmp/#{id}/a.out", __FILE__)
end
