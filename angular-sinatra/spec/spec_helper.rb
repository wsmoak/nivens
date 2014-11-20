# see http://recipes.sinatrarb.com/p/testing/rspec

require 'rack/test'

require File.expand_path '../../nivens.rb', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure { |c| c.include RSpecMixin }
