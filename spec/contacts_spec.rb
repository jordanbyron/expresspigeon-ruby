require './lib/api'
require 'pigeon_helper'

describe 'contacts integration test' do

  include PigeonSpecHelper

  it 'should not create contact without contact data' do
    resp = PIGEON.contacts.upsert(-1, {})
    validate_response resp, 400, 'error', /contact and contact.email are required/
  end
  it 'should not create contact without email' do
    resp = PIGEON.contacts.upsert(-1, {:email => '', :first_name => 'Marylin', :last_name => 'Monroe'})
    validate_response resp, 400, 'error', /contact and contact.email are required/
  end

  it 'should not add contact with too many custom fields' do
    custom_fields = {}
    (1..25).each { |n| custom_fields["custom_field_#{n}"] = n }
    resp = PIGEON.contacts.upsert(-1, {:email => "mary@e.e", :custom_fields => custom_fields})
    validate_response resp, 400, 'error', /You cannot create more than 20 custom fields. Use one of the 'custom_fields'./
  end


  it 'should not create new contact without list_id' do
    resp = PIGEON.contacts.upsert("", {:email => 'ee@e.e', :first_name => 'Marylin', :last_name => 'Monroe'})
    validate_response resp, 404, 'error', /contact=ee@e.e not found/
  end


  it 'test_create_with_suppressed_contact' do
    resp = PIGEON.contacts.upsert(-1, {:email => 'suppressed@e.e'})
    validate_response resp, 400, 'error', /contact=suppressed@e.e is in suppress list/
  end

  it 'cannot create with non-existent_list' do
    resp = PIGEON.contacts.upsert(-1, {:email => "e@e.e"})
    validate_response resp, 404, 'error', /list=-1 not found/
  end


  it 'creates list with contacts' do
    list_response = PIGEON.lists.create 'My List', 'John Doe', 'john@doe.com'
    list_id = list_response.list.id
    resp = PIGEON.contacts.upsert(list_id, email: "mary@e.e",
                                  :custom_fields => {:custom_field_1 => "custom_value_1", })
    validate_response resp, 200, 'success', /contact=mary@e.e created\/updated successfully/
    resp.contact.custom_fields.custom_field_1.should eq 'custom_value_1'
    resp.contact.email.should eq 'mary@e.e'
    resp.contact.email_format.should eq 'html'
    resp.contact.status.should eq 'ACTIVE'
    PIGEON.lists.delete(list_id)
  end


  it 'creates list non-existent custom field' do

    list_response = PIGEON.lists.create 'My List', 'John Doe', 'a@a.a'
    list_id = list_response.list.id
    resp = PIGEON.contacts.upsert(list_id, {:email => "mary@e.e", :custom_fields => {:c => "c", }})
    validate_response resp, 200, 'success', nil
    PIGEON.lists.delete(list_id)
  end

  it 'cannot export contacts from list without list_id' do
    content = ''
    PIGEON.lists.csv "-1" do |c|
      content += c
    end
    resp = JSON.parse(content)
    validate_response MetaHash.new(resp), 404, 'error', /list=-1 not found/
  end


  it 'should get contacts from suppressed list' do
    content =''
    PIGEON.lists.csv "suppress_list" do |c|
      content += c
    end
    resp = content.split /\n/
    resp.size.should eq 2
    resp[1].should =~ /"suppressed@e.e","Suppressed","Doe"/
  end

  it 'should get single contact' do
    resp = PIGEON.contacts.find_by_email 'suppressed@e.e'
    resp.email.should eq 'suppressed@e.e'
  end

  it 'should not find non existent contact' do
      resp = PIGEON.contacts.find_by_email 'a@a.a'
      validate_response resp, 404, 'error', /contact=a@a.a not found/
  end



  it 'should update contact' do

      list_response = PIGEON.lists.create('My List', 'John Doe', "a@a.a")
      resp = PIGEON.contacts.upsert list_response.list.id,
                                      :email => "mary@e.e", :first_name =>"Mary", :last_name => "Doe"
      validate_response resp, 200, 'success', /contact=mary@e.e created\/updated successfully/
      PIGEON.contacts.find_by_email("mary@e.e").last_name.should eq 'Doe'

      resp = PIGEON.contacts.upsert list_response.list.id,
                                    :email => 'mary@e.e', :first_name => 'Mary', :last_name => 'Johns'
      validate_response resp, 200, 'success', /contact=mary@e.e created\/updated successfully/
      PIGEON.contacts.find_by_email("mary@e.e").last_name.should eq 'Johns'
  end
  #
  #def test_delete_contact_with_non_existent_email(self):
  #    res = self.api.contacts.delete("g@g.g")
  #    self.assertEqual(res.code, 404)
  #    self.assertEqual(res.status, "error")
  #    self.assertEqual(res.message, "contact=g@g.g not found")
  #
  #def test_delete_supressed_contact(self):
  #    res = self.api.contacts.delete("suppressed@e.e")
  #    self.assertEqual(res.code, 400)
  #    self.assertEqual(res.status, "error")
  #    self.assertEqual(res.message, "contact=suppressed@e.e is in suppress list")
  #
  #def test_delete_single_contact_from_all_lists(self):
  #    list_response = self.api.lists.create("My List", "a@a.a", "a@a.a")
  #    self.api.contacts.upsert(list_response.list.id, {"email": "mary@e.e"})
  #
  #    res = self.api.contacts.delete("mary@e.e")
  #    self.assertEqual(res.code, 200)
  #    self.assertEqual(res.status, "success")
  #    self.assertEqual(res.message, "contact=mary@e.e deleted successfully")
  #
  #    self.api.lists.delete(list_response.list.id)
  #
  #def test_delete_single_contact_from_single_list(self):
  #    list_response = self.api.lists.create("My List", "a@a.a", "a@a.a")
  #    list_response_2 = self.api.lists.create("My List2", "a@a.a", "a@a.a")
  #    self.api.contacts.upsert(list_response.list.id, {"email": "mary@e.e"})
  #    self.api.contacts.upsert(list_response_2.list.id, {"email": "mary@e.e"})
  #
  #    res = self.api.contacts.delete("mary@e.e", list_response.list.id)
  #    self.assertEqual(res.code, 200)
  #    self.assertEqual(res.status, "success")
  #    self.assertEqual(res.message, "contact=mary@e.e deleted successfully")
  #
  #    contacts_exported = self.api.lists.csv(list_response.list.id).split("\n")
  #    self.assertEqual(len(contacts_exported), 1)
  #    contact_exported_2 = self.api.lists.csv(list_response_2.list.id).split("\n")
  #    self.assertEqual(len(contact_exported_2), 2)
  #    self.assertEqual(contact_exported_2[1], '"mary@e.e",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,')
  #
  #    self.api.lists.delete(list_response.list.id)
  #    self.api.lists.delete(list_response_2.list.id)
  #    self.api.contacts.delete("mary@e.e")






end

