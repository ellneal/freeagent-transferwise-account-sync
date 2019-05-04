FROM ruby:2.6

WORKDIR /opt/src

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install
COPY main.rb main.rb

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
