require '../lib/api'

# Get all campaigns:
puts ExpressPigeon::API.campaigns.all

puts "campaign report:"
puts ExpressPigeon::API.campaigns.report 20880

puts "bounced:"
puts ExpressPigeon::API.campaigns.bounced 3891

puts "unsubscribed:"
puts ExpressPigeon::API.campaigns.unsubscribed 3891

puts "spam:"
puts ExpressPigeon::API.campaigns.spam 3891

puts "schedule campaign"

puts ExpressPigeon::API.campaigns.schedule ({:list_id => 293, :template_id => 15233, :name => 'API Test campaign',
                                             :from_name => 'Igor Polevoy', :reply_to => 'igor@polevoy.org',
                                             :subject => 'API test', :google_analytics => true})







