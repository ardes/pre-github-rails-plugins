require File.dirname(__FILE__) + '/test_helper'

require 'asym_crypt'

context "AsymCrypt" do
  
  specify "can create key pairs of various strengths" do
    (priv, pub) = AsymCrypt.create_keys
    assert_kind_of AsymCrypt::PrivateKey, priv
    assert_kind_of AsymCrypt::PublicKey, pub
    (priv, pub) = AsymCrypt.create_keys(2048)
    assert_kind_of AsymCrypt::PrivateKey, priv
    assert_kind_of AsymCrypt::PublicKey, pub
  end
  
  specify "can create key files" do
    (priv, pub) = AsymCrypt.create_key_files(File.dirname(__FILE__) + '/fixtures/keys/test')
    assert_equal priv.to_s, File.read(File.dirname(__FILE__) + '/fixtures/keys/test')
    assert_equal pub.to_s,  File.read(File.dirname(__FILE__) + '/fixtures/keys/test.pub')
  end
  
  specify "can dump keys to file" do
    (priv, pub) = AsymCrypt.create_keys
    priv.to_file(File.dirname(__FILE__) + '/fixtures/keys/test')
    assert_equal priv.to_s, File.read(File.dirname(__FILE__) + '/fixtures/keys/test')
    pub.to_file(File.dirname(__FILE__) + '/fixtures/keys/test.pub')
    assert_equal pub.to_s, File.read(File.dirname(__FILE__) + '/fixtures/keys/test.pub')
  end
  
  specify "can instantiate public key from file" do
    key = AsymCrypt.key_from_file(File.dirname(__FILE__) + '/fixtures/keys/test_key.pub')
    assert_kind_of AsymCrypt::PublicKey, key
  end
  
  specify "can instantiate public key from text" do
    key = AsymCrypt.key(
<<-end_key
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBALwxXIkH338pqRGwHEh7LJKNgDN/KYNrmWub71jmIEHSTlyyjpF/VMkc
0V3G4V5dNYFzOCyimWeLkWNyqWQ5M39uIYsZWAvrTH21GHG8rZJeple2Pl2PJDdL
1PLdVvWOuJmCFq+ob0CYpdRXZFCEO7JBhV6gelVw02LXCeK481YpAgMBAAE=
-----END RSA PUBLIC KEY-----
end_key
    )
    assert_kind_of AsymCrypt::PublicKey, key
  end
  
  specify "can instantiate private key from file" do
    key = AsymCrypt.key_from_file(File.dirname(__FILE__) + '/fixtures/keys/test_key')
    assert_kind_of AsymCrypt::PrivateKey, key
  end

  specify "can instantiate private key from text" do
    key = AsymCrypt.key(
<<-end_key
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQC8MVyJB99/KakRsBxIeyySjYAzfymDa5lrm+9Y5iBB0k5cso6R
f1TJHNFdxuFeXTWBczgsoplni5FjcqlkOTN/biGLGVgL60x9tRhxvK2SXqZXtj5d
jyQ3S9Ty3Vb1jriZghavqG9AmKXUV2RQhDuyQYVeoHpVcNNi1wniuPNWKQIDAQAB
AoGBALFd+G+x+uO3mP/xsoZhiL3LHSPr2m1hUOSJwAhSQ96lXnOhWhspHfi5711p
3uh4AsCxniT7Toe3k9xdqeaqvqvhdI8OeFxZS5mXmxWi872yRYLPeEhRnWTllTyl
YLLEaF7rfSqOiL0pMJdPNkPAPDRd+VJdOd/5DzpxIbw9rUxdAkEA7IBJ20ntnUxo
pCsHx+k+RzV/5CYksizeBTnI/Tk7jjFEozW89irxw6dNmYrT/LDR6AoaVmkhZr8K
3lx/H6s64wJBAMu1dBvrHi+Yfx8j/kRBOTr1j7RfjTxAfqsmTA/QouIMcloPa9xu
ztnYLrgfm/XI/CacpFJfO6UewLiBbxcNPIMCQQDE+qEJRUzke7SYL8LeTbVyZ+vq
YZ6kzFvrbFKsHlQtPXnWmjaVrfUJqbonTYr852UdZ/TBzfRk+G+b/txeyyZTAkBi
iuGjC8brcVK1Zrz+maqsudONhteUuQJNmtYapGvW+/xpUqJz3OqVeT2IdkoEyPgp
WYcoDceVpd3Go15xAUcvAkEAo515YlWMUdB6QTDRu0wbT7LiQjtxA7qQbvnnJLn8
RwVNAZpgui22t3cFgd8W0Gw4qkI1sDfqIuVFchX5huBe7A==
-----END RSA PRIVATE KEY-----
end_key
    )
    assert_kind_of AsymCrypt::PrivateKey, key
  end
  
  specify "can instantiate key pair from files" do
    (priv, pub) = AsymCrypt::keys_from_file(File.dirname(__FILE__) + '/fixtures/keys/test_key')
    assert_kind_of AsymCrypt::PrivateKey, priv
    assert_kind_of AsymCrypt::PublicKey, pub
  end
  
  specify "should perform digital signing (private encrypt)" do
    signed = ["from Santa Claus", Time.now]
    (priv, pub) = AsymCrypt.create_keys
    cryptext = priv.encrypt(signed)
    assert((signed != cryptext), 'signed should not be equal to cryptext')
    assert_equal signed, pub.decrypt(cryptext)
  end
  
  specify "should perform asym encryption (public encrypt)" do
    secret = {:message => "there is no Santa Claus", :time => Time.now}
    (priv, pub) = AsymCrypt.create_keys
    cryptext = pub.encrypt(secret)
    assert((secret != cryptext), 'secret should not be equal to cryptext')
    assert_equal secret, priv.decrypt(cryptext)
  end
end