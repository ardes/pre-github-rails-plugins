require File.dirname(__FILE__) + '/test_helper'

class Secret < ActiveRecord::Base
  (TimePrivateKey, TimePublicKey) = AsymCrypt::create_keys 

  asym_encrypt :text, :as => :text_crypt
  asym_encrypt :time, :as => :time_crypt, :class => Time, :encryption_key => TimePublicKey
end

context "ActiveRecord AsymCrypt" do
  
  (PublicKey, PrivateKey) = AsymCrypt::create_keys
  SecretText = "I wanted to be a ballerina"
  SecretTime = Time.mktime(1971,8,27)
  
  def setup
    Secret.destroy_all
    Secret.encryption_key = PublicKey
    @secret = Secret.create(:text => SecretText, :time => SecretTime)
    @secret.reload
    Secret.encryption_key = nil
    Secret.decryption_key = nil
  end
  
  specify "should be able to copy without decryption key" do
    copied = Secret.new
    copied.attributes = @secret.attributes
    copied.save
    assert_equal @secret.text_crypt, copied.text_crypt
  end
  
  specify "should raise error when decrypting if no decryption key available" do
    assert_raises(ActiveRecord::AsymCrypt::DecryptionKeyRequired) { @secret.text }
  end
  
  specify "should decrypt when class decryption key available" do
    Secret.decryption_key = PrivateKey
    assert_equal SecretText, @secret.text
  end
  
  specify "should attempt decyrpt and fail when decrypting with wrong key" do
    Secret.decryption_key = PrivateKey
    assert_raises(OpenSSL::PKey::RSAError) { @secret.time } 
  end
  
  specify "should attributes when multiple decryption keys available" do
    Secret.decryption_key = PrivateKey
    Secret.time_decryption_key = Secret::TimePrivateKey
    assert_equal SecretText, @secret.text
    assert_equal SecretTime, @secret.time
  end
end