FROM simodak/ubuntu-zapcc:18.04

RUN apt update && apt install -y ruby git && apt clean && rm -rf /var/lib/apt/lists/*
RUN gem install sinatra

RUN cd  && git clone --recursive https://github.com/boostorg/boost.git && cd ~/boost && ./bootstrap.sh && ./b2 install -j2 --prefix=/opt/boost/

COPY src /var/app
CMD ruby /var/app/nekosuna.rb
