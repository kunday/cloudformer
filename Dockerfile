FROM ruby:2.1.2

ADD . /usr/local/app
WORKDIR /usr/local/app
RUN bundle install
