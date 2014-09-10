# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
#
# Usage Example : Run One-Off commands
# See : https://github.com/phusion/baseimage-docker#oneshot for more examples.
#
#  docker build -t="grempe/dmr-watch" --no-cache=true .
#  docker run --rm -t -i --name dmr_watch -P  grempe/dmr-watch /sbin/my_init -- bash -l

FROM phusion/baseimage:0.9.13
MAINTAINER Glenn Rempe

# Set correct environment variables.
#ENV HOME /root
RUN echo /root > /etc/container_environment/HOME

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
#RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Baseimage-docker enables an SSH server by default, so that you can use SSH
# to administer your container. In case you do not want to enable SSH, here's
# how you can disable it. Uncomment the following:
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /tmp

# See : https://github.com/phusion/baseimage-docker/issues/58
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2014-09-09

# Update repos
RUN apt-get -q update

# Install wget
RUN apt-get -q install -y wget

# Install unzip
RUN apt-get -q install -y unzip

# Install git
RUN apt-get -q install -y git

# Add Erlang Solutions repo
# See : https://www.erlang-solutions.com/downloads/download-erlang-otp
RUN echo "deb http://packages.erlang-solutions.com/ubuntu trusty contrib" >> /etc/apt/sources.list
RUN wget -q https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc
RUN apt-key add erlang_solutions.asc
RUN apt-get -qq update

# Download and Install Specific Version of Erlang
RUN apt-get install -y erlang=1:17.1

# Download and Install Specific Version of Elixir
WORKDIR /elixir
RUN wget -q https://github.com/elixir-lang/elixir/releases/download/v1.0.0-rc2/Precompiled.zip
RUN unzip Precompiled.zip
RUN rm -f Precompiled.zip
RUN ln -s /elixir/bin/elixirc /usr/local/bin/elixirc
RUN ln -s /elixir/bin/elixir /usr/local/bin/elixir
RUN ln -s /elixir/bin/mix /usr/local/bin/mix
RUN ln -s /elixir/bin/iex /usr/local/bin/iex

# Create an Elixir user to run all beam code
RUN useradd elixir -m -s /bin/bash

# Install local Elixir hex and rebar
RUN /sbin/setuser elixir /usr/local/bin/mix local.hex --force
RUN /sbin/setuser elixir /usr/local/bin/mix local.rebar --force

# Install a copy of the Elixir Phoenix app
ADD config/  /home/elixir/app/config/
ADD lib/     /home/elixir/app/lib/
ADD priv/    /home/elixir/app/priv/
ADD test/    /home/elixir/app/test/
ADD web/     /home/elixir/app/web/
ADD mix.exs  /home/elixir/app/mix.exs
ADD mix.lock /home/elixir/app/mix.lock
RUN chown -R elixir:elixir /home/elixir/app

WORKDIR /home/elixir/app
RUN /sbin/setuser elixir mix deps.clean --all
RUN /sbin/setuser elixir mix clean --all
RUN /sbin/setuser elixir mix deps.get
RUN /sbin/setuser elixir mix deps.compile
RUN /sbin/setuser elixir mix compile.protocols

# Elixir Phoenix Runit Script
RUN mkdir /etc/service/phoenix
ADD docker/phoenix.sh /etc/service/phoenix/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV MIX_ENV prod
ENV PORT 4000
EXPOSE 4000

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
