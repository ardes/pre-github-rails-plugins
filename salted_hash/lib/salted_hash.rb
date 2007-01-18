require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'

# Set of convenience methods for computing salted hash passwords.
#
# The return values for the hash, and salt are hex pair strings (although the salt is converted to
# binary for the computation of the hash).
# If you wish, you can convert these to 8-bit binary strings using hex_to_binary
#
module SaltedHash
  SALT_LENGTH = 20
  
  # return array of the supported algorithms
  def self.algorithms
    @algorithms ||= ['md5', 'sha1', 'sha256', 'sha384', 'sha512']
  end
  
  # raise an error if the argument is not a supported algorithm
  def self.assert_supported_algorithm(algorithm)
    raise ArgumentError, "Unsupported algorithm '#{algorithm}'" unless algorithms.include?(algorithm.to_s.downcase)
  end
  
  # computes a hash (hex pair format) given a digest algorithm name (see algorithms), salt string (hex pair format) and password string
  def self.compute(algorithm, salt, password)
    assert_supported_algorithm(algorithm)
    digest = "Digest::#{algorithm.upcase}".constantize
    digest.hexdigest("#{hex_to_binary(salt)}#{password}")
  end
  
  # creates a random salt (a hex pair string) of given length (default SALT_LENGTH)
  def self.salt(length = SALT_LENGTH)
    (1..length).inject(''){|s,_| s << '%02x' % rand(256)}
  end
  
  # takes a string of hexadecimal pairs and converts it to a string of 8-bit bytes
  def self.hex_to_binary(hex)
    hex.unpack('a2' * (hex.length/2)).inject(''){|s,c| s << c.hex}
  end
  
  # takes an 8-bit binary string and converts it to a string of hexadecimal pairs
  def self.binary_to_hex(binary)
    binary.unpack('C' * binary.length).inject(''){|s,c| s << '%02x' % c}
  end
end