require 'net/http'
require 'json'
require 'uri'

AUTH_KEY = ENV['EXPRESSPIGEON_AUTH_KEY']
#ROOT = 'https://api.expresspigeon.com/'
ROOT = 'http://localhost:8888/api/'
USE_SSL=false

module ExpressPigeon
  module API

    unless AUTH_KEY
      raise 'Provide EXPRESSPIGEON_AUTH_KEY environment variable'
    end

    def http(path, method, params = {})
      uri = URI.parse "#{ROOT}#{path}"
      req = Net::HTTP.const_get("#{method}").new "#{ROOT}#{path}"
      req['X-auth-key'] = AUTH_KEY
      if params
        req.body = params.to_json
        req['Content-type'] = 'application/json'
      end

      if block_given?
        Net::HTTP.start(uri.host, uri.port, :use_ssl => USE_SSL) do |http|
          http.request req do |res|
            res.read_body do |seg|
              yield seg
            end
          end
        end
      else
        resp = Net::HTTP.start(uri.host, uri.port, :use_ssl => USE_SSL) do |http|
          http.request req
        end
        resp = JSON.parse(resp.body)
        if resp.kind_of? Hash
          MetaHash.new resp
        else
          resp
        end

      end

    end

    def get(path, &block)
      http path, 'Get', nil, &block
    end

    def post(path, params = {})
      http path, 'Post', params
    end

    def del(path, params = {})
      http path, 'Delete', params
    end

    def self.campaigns
      Campaigns.new
    end

    def self.lists
      Lists.new
    end

    def self.contacts
      Contacts.new
    end
  end

end

class MetaHash < Hash

  def initialize(delegate)
    super
    @delegate = delegate
    @delegate.each_key do | k |
      v = @delegate[k]  # lets go only one level down for now
      if v.kind_of? Hash
        @delegate[k] = MetaHash.new(v)
      end
    end
  end

  def method_missing(m, *args, &block)
    @delegate[m.to_s]
  end
end

class Lists

  include ExpressPigeon::API

  def initialize
    @endpoint = 'lists'
  end

  def create(list_name, from_name, reply_to)
    post @endpoint, {:name => list_name, :from_name => from_name, :reply_to => reply_to}
  end


  # Query all lists.
  # returns: array of hashes each representing a list for this user
  def all
    get @endpoint
  end


  # Removes a list with a given id. A list must be enabled and has no dependent subscriptions and/or scheduled campaigns.
  #
  #  param list_id: Id of list to be removed.
  #  returns response hash with status, code, and message
  def delete(list_id)
    del "#{@endpoint}/#{list_id}"
  end

  def csv(list_id, &block)
    get "#{@endpoint}/#{list_id}/csv", &block
  end


end

class Campaigns
  include ExpressPigeon::API

  def initialize
    @endpoint = 'campaigns'
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
  def send(params = {})
    post @endpoint, params
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


class Contacts
  include ExpressPigeon::API

  def initialize
    @endpoint = 'contacts'
  end

  def find_by_email(email)
    get "#{@endpoint}?email=#{email}"
  end


  # JSON document represents a contact to be created or updated.
  # The email field is required.
  # When updating a contact, list_id is optional,
  # since the contact is uniquely identified by email across all lists.
  #
  # :param list_id: Contact list ID (Fixnum) the contact will be added to
  #
  # :param contact: Hash describes new contact. The "email" field is required.
  #
  # :returns: representation of a contact
  #
  def upsert(list_id, contact)
    post @endpoint, params={:list_id => list_id, :contact => contact}
  end

  # Delete single contact. If list_id is not provided, contact will be deleted from system.
  # :param email: contact email to be deleted.
  # :param list_id: list id to remove contact from, if not provided, contact will be deleted from system.
  def delete(email, list_id)
    query = "email=#{email}&list_id=#{list_id}"
    del "#{@endpoint}?#{query}", nil
  end

  #TODO improve method name, once I learn Ruby :)
  def delete_from_system(email)
    query = "email=#{email}"
    del "#{@endpoint}?#{query}", nil
  end
end
