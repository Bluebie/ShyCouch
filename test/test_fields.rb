require 'test/unit'
require_relative '../lib/ShyCouch.rb'

class TestEmailField < Test::Unit::TestCase
  def setup
    @valid_emails = ['bigbeggar@gmail.com', 'helpmeout@bigpond.com'] # more!
    @invalid_emails = ['byby.head@heat']#, 'looptheloop@ireallyhopethisisntadomainpleasedontbeadomain.org'] # more!
    #commented out the one with an invalid domain cos resolve timeout long
  end
  
  def teardown; end
  
  def test_valid_emails
    @valid_emails.each do |email|
      email_addr = ShyCouch::Fields::Email_Addr.new(email)
      assert_equal(true, email_addr.valid?)
    end
  end
  
  def test_invalid_emails
    @invalid_emails.each do |email|
       email_addr = ShyCouch::Fields::Email_Addr.new(email)
       assert_equal(false, email_addr.valid?)
     end
  end
end