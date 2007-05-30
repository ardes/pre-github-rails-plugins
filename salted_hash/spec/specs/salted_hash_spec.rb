require File.join(File.dirname(__FILE__), '../spec_helper')

describe "The SaltedHash module" do
  it "should compute a salted hash with compute(algorithm, salt, pass)" do
    SaltedHash.compute('md5', '0f8a', 'pass').should be_kind_of(String)
  end

  it "should compute a salted hash for each supported algorithm" do
    SaltedHash.algorithms.each do |a|
      lambda{ hash = SaltedHash.compute(a, 'secret', '0f8b') }.should_not raise_error
    end
  end
  
  it "should raise an error with assert_supported_algorithm when algorithm unsupported" do
    lambda{SaltedHash.assert_supported_algorithm('foo')}.should raise_error(ArgumentError)
  end
  
  it "should return a random string in hex format with salt" do
    salt = SaltedHash.salt
    salt.should be_kind_of(String)
    SaltedHash.binary_to_hex(SaltedHash.hex_to_binary(salt)).should == salt
  end
  
  it "should return a random string in hex format of specified length with salt(length)" do
    SaltedHash.salt(10).length.should == 20
  end
  
  it "should convert strings from binary to hexadecimal with binary_to_hex" do
    random = SaltedHash.salt
    SaltedHash.binary_to_hex(random).length.should == random.length * 2
    SaltedHash.hex_to_binary(SaltedHash.binary_to_hex(random)).should == random
  end
  
  it "should convert strings from hexadecimal to binary with hex_to_binary" do
    ['00000000', 'FFFFFFFF', SaltedHash.binary_to_hex(SaltedHash.salt)].each do |hex|
      SaltedHash.hex_to_binary(hex).length.should == hex.length / 2
      SaltedHash.binary_to_hex(SaltedHash.hex_to_binary(hex)).should == hex.downcase
    end
  end
end
