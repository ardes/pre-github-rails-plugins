require File.dirname(__FILE__) + '/test_helper'

# active record with two encrypted attributes, one of which is encyrypted with its
# own key (:time attr), the other is encrypted with the default key
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
    @secret = Secret.new(:text => SecretText, :time => SecretTime)
    @secret.encryption_key = PublicKey
    @secret.save
    @secret = Secret.find(@secret.id)
  end
  
  specify "should have attr? operator that does not raise key required error" do
    assert !@secret.time?
    assert !@secret.text?
    @secret.decryption_key = PrivateKey
    assert !@secret.time? # time has it's own key
    assert @secret.text?
    @secret.time_decryption_key = Secret::TimePrivateKey
    assert @secret.time?
  end
  
  specify "should be able to copy without decryption key" do
    copied = Secret.new
    copied.attributes = @secret.attributes
    copied.save
    assert_equal @secret.text_crypt, copied.text_crypt
  end
  
  specify "should raise error when decrypting if no decryption key available" do
    assert_raises(ActiveRecord::AsymCrypt::DecryptionKeyRequired) { @secret.text }
    assert_raises(ActiveRecord::AsymCrypt::DecryptionKeyRequired) { @secret.time }
  end
  
  specify "should decrypt when only class decryption key available" do
    Secret.decryption_key = PrivateKey
    assert_equal SecretText, @secret.text
    Secret.decryption_key = nil
  end
  
  specify "should decrypt when only ActiveRecord decryption key available" do
    ActiveRecord::AsymCrypt.decryption_key = PrivateKey
    assert_equal SecretText, @secret.text
    ActiveRecord::AsymCrypt.decryption_key = nil
  end
  
  specify "should attempt decyrpt and fail when decrypting with wrong key" do
    @secret.decryption_key = PrivateKey
    assert_raises(OpenSSL::PKey::RSAError) { @secret.time } 
  end
  
  specify "should decrypt attributes when multiple decryption keys available" do
    @secret.decryption_key = PrivateKey
    @secret.time_decryption_key = Secret::TimePrivateKey
    assert_equal SecretText, @secret.text
    assert_equal SecretTime, @secret.time
  end
  
  specify "should raise error when encrypting with no encryption key available" do
    assert_raises(ActiveRecord::AsymCrypt::EncryptionKeyRequired) do
      s = Secret.new
      s.text = 'a secret'
      s.text_crypt
    end
  end
  
  specify "should encrypt when encryption key available" do
    s = Secret.new
    s.time = Time.now
    assert s.time_crypt
  end
  
  specify "should raise type mismatch if encrypting with wrong type" do
    assert_raise(ActiveRecord::SerializationTypeMismatch) do
      @secret.time = 'not a time'
      @secret.time_crypt
    end
  end
  
  specify "should raise type mismatch if decrypted is wrong type" do
    @secret.time_crypt = Secret::TimePublicKey.encrypt('not a time')
    @secret.time_decryption_key = Secret::TimePrivateKey
    assert_raise(ActiveRecord::SerializationTypeMismatch) { @secret.time }
  end
  
  specify "should change cryptext when content of attr changes (for non value objects)" do
    @secret.encryption_key = PublicKey
    @secret.text = [1,2,3]
    cryptext = @secret.text_crypt
    @secret.text << 4
    assert(cryptext != @secret.text_crypt, "cryptext should have changed")
  end
end

context "ActiveRecord AsymCrypt Keys" do
  
  class Crypt < ActiveRecord::Base
    acts_as_tableless :text
    asym_encrypt :text, :as => :text_crypt
  end
  
  def setup
    ActiveRecord::AsymCrypt.encryption_key = nil
    ActiveRecord::AsymCrypt.decryption_key = nil
    Crypt.encryption_key = nil
    Crypt.decryption_key = nil
    Crypt.text_encryption_key = nil
    Crypt.text_encryption_key = nil
    @crypt = Crypt.new
  end
  
  specify "should search for keys in order: instance attribute, attribute, instance, class, active_record" do
    ActiveRecord::AsymCrypt.encryption_key = :active_record
    assert_equal :active_record, @crypt.send(:get_key, :encryption, :text)
    Crypt.encryption_key = :class_class
    assert_equal :class_class, @crypt.send(:get_key, :encryption, :text)
    @crypt.encryption_key = :instance_class
    assert_equal :instance_class, @crypt.send(:get_key, :encryption, :text)
    Crypt.text_encryption_key = :class_attribute
    assert_equal :class_attribute, @crypt.send(:get_key, :encryption, :text)
    Crypt.text_encryption_key = :instance_attribute
    assert_equal :instance_attribute, @crypt.send(:get_key, :encryption, :text)
  end
end