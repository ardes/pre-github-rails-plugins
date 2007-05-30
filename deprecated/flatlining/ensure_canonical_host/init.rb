require 'ardes/ensure_canonical_host'
ActionController::Base.class_eval { extend Ardes::ActionController::EnsureCanonicalHost }