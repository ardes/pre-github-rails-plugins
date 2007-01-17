require File.join(File.dirname(__FILE__), 'spec_helper')

context "The SaltedHash module" do
  specify "should compute a salted hash with compute(algorithm, salt, pass)" do
    SaltedHash.compute('md5', 'salt', 'pass').should_be_kind_of(String)
  end

  specify "should compute a salted hash for each supported algorithm" do
    SaltedHash.algorithms.each do |a|
      lambda{ hash = SaltedHash.compute(a, 'salt', 'secret')}.should_not_raise
    end
  end
  
  specify "should return a random string with salt" do
    SaltedHash.salt.should_be_kind_of(String)
  end
  
  specify "should convert strings from binary to hexadecimal with binary_to_hex" do
    random = SaltedHash.salt
    should_satisfy { SaltedHash.binary_to_hex(random).length == random.length * 2 }
    SaltedHash.hex_to_binary(SaltedHash.binary_to_hex(random)).should == random
  end
  
  specify "should convert strings from hexadecimal to binary with hex_to_binary" do
    ['00000000', 'FFFFFFFF', SaltedHash.binary_to_hex(SaltedHash.salt)].each do |hex|
      should_satisfy { SaltedHash.hex_to_binary(hex).length == hex.length / 2 }
      SaltedHash.binary_to_hex(SaltedHash.hex_to_binary(hex)).should == hex.downcase
    end
  end
end
