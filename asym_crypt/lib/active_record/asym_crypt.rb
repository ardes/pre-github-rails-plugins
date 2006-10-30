require 'asym_crypt'

module ActiveRecord
  # Asymetric encryption of ActiveRecord attributes.
  #
  # This extension allows asymetric encryption both for digital signing (encrypted with private key, and decrypted with public key),
  # and the more common case of encryption with a public key, only decryptable with a private key.
  #
  # Using this you can, for example, encrypt your customers credit card details with a public key stored on your webserver.  You can then
  # write a processing application on a different server, which has the private key and can read the data.  Another approach might be
  # to have the appropriate user paste the private key into a form, which is then kept for the session in the user's browser via a
  # cookie (*not* in the session, or server).
  # 
  # Both of these approaches keep the encryption and decryption methods separated and the keys are never in the same place (on the server)
  #
  # === Usage
  #
  # asym_encrypt <em>decrypted_attr</em>, :as => <em>crypt_col</em> [, options]
  #
  # Typically <em>crypt_col</em> will be a database column.  <em>decrypted_attr</em> becomes
  # an encryption wrapper for the database column.  The following accessor methods are created:
  #
  #  * <tt>decrypted_attr=</tt> encrypts the argument with the encryption key (see below for how keys are found).
  #     Raises EncryptionKeyRequired if none can be found.
  #  * <tt>decrypted_attr</tt> decrypts (and caches) the argument with the decryption key.  Raises DecryptionKeyRequired if
  #     none can be found.
  #  * <tt>decrypted_attr?</tt> returns true if there is a non false, nor nil, decrypted object, without raising any errors
  #
  # Unlike serialize, asym_crypt keeps the database column (in this case the cryptext) encoded in its original format.  This
  # allows the possibility of copying a record without knowing how to decrypt all of its attributes.
  #
  # ==== Options
  #  * <tt>:encryption_key</tt>: use specified key (an AysmCrypt::Key) to encrypt this attribute
  #  * <tt>:decryption_key</tt>: use specified key (an AsymCrypt::Key) to decrypt this attribute
  #  * <tt>:class</tt>: make sure the decrypted object is of the specifed class, raising SerializationTypeMismatch if not
  # 
  # The encryption and decryption keys can be specified on the class, and these will be used for all (en/de)cryption if the
  # keys are not specified on the attribute
  #
  # If you want to set key(s) for your whole application, then do this:
  #   ActiveRecord::AsymCrypt.encryption_key = (your key)
  #   ActiveRecord::AsymCrypt.decryption_key = (your key)
  #
  # Keys will be searched first on the object (on an attribute), then on the class, then on ActiveRecord::AsymCrypt
  #
  # See AsymCrypt for details on creating and reading keys.
  #
  # === Example
  #   class Secret < ActiveRecord::Base
  #     asym_crypt :encrypt => :secret_cryptext, :as => :secret
  #   end
  #
  #   @secret = Secret.new
  #   @secret.crypted_attributes              # => {:secret => {:encrypt => :secret_text, :class => Object}}
  # 
  #   @secret.secret = 'I am green'           # => raises EncryptionKeyRequired
  #
  #   Secret.encryption_key = AsymCrypt.key_from_file('my/key/location.pub')
  #                                           # set public key for encryption on class
  #
  #   @secret.secret_encryption_key           # => the AsymCrypt::PublicKey above
  #   @secret.secret_decryption_key           # => nil
  #   
  #   @secret.secret?                         # => true
  #   @secret.secret_cryptext                 # => (the cryptext)
  #   @secret.secret                          # => 'I am green'
  #  
  module AsymCrypt
    
    class EncryptionKeyRequired < ::RuntimeError; end
    
    class DecryptionKeyRequired < ::RuntimeError; end
    
    mattr_accessor :encryption_key, :decryption_key
    
    def asym_encrypt(attr_name, options = {})
      append_features_to_active_record unless self.included_modules.include? ActiveRecord::AsymCrypt::InstanceMethods
      raise ArgumentError, 'asym_encrypt requires :as => crypt_col option' unless options[:as]
      options[:class] ||= Object
      asym_encrypted_attributes[attr_name] = options.dup
      define_asym_crypt_methods(attr_name, options)
    end
  
  protected
    def append_features_to_active_record
      self.class_eval do
        extend ClassMethods
        include InstanceMethods
        class_inheritable_accessor :encryption_key, :decryption_key
        write_inheritable_attribute("attr_asym_encrypted", {})
      end
    end
    
    def define_asym_crypt_methods(attr_name, config)
      crypt_col = config[:as]
      
      class_eval <<-end_eval
        # class method accessors for (en/de)cryption keys per attribute
        class <<self
          def #{attr_name}_encryption_key; asym_encrypted_attributes[:#{attr_name}][:encryption_key]; end
          def #{attr_name}_decryption_key; asym_encrypted_attributes[:#{attr_name}][:decryption_key]; end
          def #{attr_name}_encryption_key=(key); asym_encrypted_attributes[:#{attr_name}][:encryption_key] = key; end
          def #{attr_name}_decryption_key=(key); asym_encrypted_attributes[:#{attr_name}][:decryption_key] = key; end
        end
        
        # accessors for encryption wrapper attribute
        def #{attr_name}?
          !!#{attr_name} rescue nil
        end
        
        def #{attr_name}
          @#{attr_name} or @#{attr_name} = decrypt_attribute(:#{attr_name}, #{crypt_col})
        end
        
        def #{attr_name}=(plain)
          write_attribute(:#{crypt_col}, encrypt_attribute(:#{attr_name}, plain))
          @#{attr_name} = plain
        end
        
        # writer for encrypted attribute, which clears the cached decrypted attribute
        def #{crypt_col}=(cryptext)
          @#{attr_name} = nil
          write_attribute("#{crypt_col}", cryptext)
        end
      end_eval
    end
        
    module InstanceMethods
      def self.included(base)
        base.class_eval do
          alias_method_chain :reload, :asym_crypt
        end
      end
      
      def reload_with_asym_crypt
        asym_encrypted_attributes.keys.each {|attr_name| instance_variable_set("@#{attr_name}", nil)}
        reload_without_asym_crypt
      end
      
      # returns the first public key found, first for the specified attribute (not required)
      # then the class, and finally the ActiveRecord::AsymCrypt
      def get_encryption_key(attr_name = nil)
        attr_encryption_key = attr_name ? asym_encrypted_attributes[attr_name][:encryption_key] : nil
        attr_encryption_key or self.encryption_key or ::ActiveRecord::AsymCrypt.encryption_key
      end
      
      # returns the first private key found, first for the specified attribute (not required)
      # then the class, and finally the ActiveRecord::AsymCrypt
      def get_decryption_key(attr_name = nil)
        attr_decryption_key = attr_name ? asym_encrypted_attributes[attr_name][:decryption_key] : nil
        attr_decryption_key or self.decryption_key or ::ActiveRecord::AsymCrypt.decryption_key
      end

      def asym_encrypted_attributes
        self.class.asym_encrypted_attributes
      end
      
    protected

      def encrypt_attribute(attr_name, plain)  
        raise EncryptionKeyRequired unless (key = get_encryption_key(attr_name)).is_a?(::AsymCrypt::Key)
        raise ::ActiveRecord::SerializationTypeMismatch unless plain.is_a?(asym_encrypted_attributes[attr_name][:class])
        key.encrypt(plain)
      end
      
      def decrypt_attribute(attr_name, cryptext)
        return nil if cryptext.nil?
        raise DecryptionKeyRequired unless (key = get_decryption_key(attr_name)).is_a?(::AsymCrypt::Key)
        raise ::ActiveRecord::SerializationTypeMismatch unless (plain = key.decrypt(cryptext)).is_a?(asym_encrypted_attributes[attr_name][:class])
        plain
      end
    end
    
    module ClassMethods
      def asym_encrypted_attributes
        read_inheritable_attribute("attr_asym_encrypted")
      end
    end
  end
end