FROM simodak/ubuntu-zapcc:18.04

RUN apt update && apt install -y ruby git python3-pip openjdk-11-jdk && apt clean && rm -rf /var/lib/apt/lists/*
RUN gem install sinatra -v 2.2.4

RUN cd && git clone --recursive https://github.com/boostorg/boost.git && cd ~/boost && ./bootstrap.sh && ./b2 install -j2 --prefix=/opt/boost/
RUN cd && git clone https://github.com/atcoder/ac-library.git

RUN pip3 install numpy

RUN apt update && apt install -y curl pkg-config libssl-dev && apt clean && rm -rf /var/lib/apt/lists/*
RUN curl -orustup.sh https://sh.rustup.rs && chmod 755 ./rustup.sh && ./rustup.sh -y && rm ./rustup.sh
RUN /root/.cargo/bin/cargo install sccache
ENV RUSTC_WRAPPER /root/.cargo/bin/sccache

COPY src /var/app
CMD ruby /var/app/nekosuna.rb
