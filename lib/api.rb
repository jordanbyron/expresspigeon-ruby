require 'net/http'
require 'json'
require 'uri'


module ExpressPigeon
  module API
    ROOT = 'https://api.expresspigeon.com/'
    AUTH_KEY = ENV['EXPRESSPIGEON_AUTH_KEY']
    unless AUTH_KEY
      raise 'Provide EXPRESSPIGEON_AUTH_KEY environment variable'
    end

    def post

    end

    def get(endpoint)
      uri = URI.parse("#{ROOT}#{endpoint}")
      req = Net::HTTP::Get.new uri.path
      req['X-auth-key'] = AUTH_KEY
      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.request req
      end
      JSON.parse(res.body)
    end

    def self.campaigns
      Campaigns.new
    end
  end
end


class Campaigns
  include ExpressPigeon::API
  def initialize
    @endpoint = "campaigns"
  end

  def all
    get @endpoint
  end
end


# Get all campaigns:
x = ExpressPigeon::API.campaigns.all
puts x









