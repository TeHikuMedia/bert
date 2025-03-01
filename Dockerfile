FROM nvidia/cuda:10.2-cudnn7-runtime-ubuntu18.04

# Use New Zealand mirrors
RUN sed -i 's/archive/nz.archive/' /etc/apt/sources.list

RUN apt update

# Set timezone to Auckland
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales tzdata
RUN locale-gen en_NZ.UTF-8
RUN dpkg-reconfigure locales
RUN echo "Pacific/Auckland" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
ENV LANG en_NZ.UTF-8
ENV LANGUAGE en_NZ:en

# Create user 'kaimahi' to create a home directory
RUN useradd kaimahi
RUN mkdir -p /home/kaimahi/
RUN chown -R kaimahi:kaimahi /home/kaimahi
ENV HOME /home/kaimahi

# Install apt packages
RUN apt update
RUN apt install -y gcc libffi-dev git

# Install python + other things
RUN apt update
RUN apt install -y python3-dev python3-pip
RUN pip3 install --upgrade "pip < 21.0"

COPY requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt

RUN pip3 install nvidia-pyindex
RUN pip3 install nvidia-tensorflow[horovod]
