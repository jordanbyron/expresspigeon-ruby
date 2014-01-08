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

    def post(endpoint, params = {})
      uri = URI.parse("#{ROOT}#{endpoint}")
      req = Net::HTTP::Post.new uri.path
      req.body = params.to_json
      req['X-auth-key'] = AUTH_KEY
      req['Content-type'] = 'application/json'
      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.request req
      end
      JSON.parse(res.body)
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

  def report(campaign_id)
    get "#{@endpoint}/#{campaign_id}"
  end

  def bounced(campaign_id)
    get "#{@endpoint}/#{campaign_id}/bounced"
  end

  def unsubscribed(campaign_id)
    get "#{@endpoint}/#{campaign_id}/unsubscribed"
  end

  def spam(campaign_id)
    get "#{@endpoint}/#{campaign_id}/spam"
  end

  #
  # Schedules a new campaign to be sent.
  # Parameters:
  # * *list_id* - id of list to send to
  # * *template_id* - id of template to send
  # * *name* - name of a newly created campaign
  # * *from_name* - from name
  # * *reply_to* - reply to
  # * *subject* - subject of campaign
  # * *google_analytics* - true to turn Google Analytics on
  # * *schedule_for* - Specifies what time a campaign should be sent. If it is provided the campaign will
  #                     be scheduled to this time, otherwise campaign is sent immediately. The schedule_for
  #                     must be in ISO date format and should be in the future.
  def schedule(params = {})
    post @endpoint, params
  end
end
