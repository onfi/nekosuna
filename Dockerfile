FROM simodak/ubuntu-zapcc:18.04

RUN apt update && apt install -y ruby && apt clean && rm -rf /var/lib/apt/lists/*
RUN gem install sinatra

COPY src /var/app
CMD ruby /var/app/nekosuna.rb
