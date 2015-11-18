FROM ubuntu:14.04

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
ADD install_dependencies.sh /tmp/install_dependencies.sh
RUN chmod a+x /tmp/install_dependencies.sh
RUN /tmp/install_dependencies.sh

RUN apt-get clean
