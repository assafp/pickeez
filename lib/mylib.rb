# The Darkest Ruby Magic.
require 'active_support/core_ext/hash/indifferent_access'

module Enumerable
  # Enable dot access on hashes and hash-like objects.
  # {b:2}.b == {'b' => 2}.b == 2. 
  def method_missing(method, *args)
    return if method == "kind_of?"  # This should never happen, but just in case..
    return if self.kind_of? Array
    if method =~ /=$/
      # Protip: $` means "the string before the last Regex match".
      self[$`.to_sym] = args[0]
    else
      self[method.to_sym] || self[method.to_s]
    end
  end
end

class Hash
  def and(params)
    self.merge(params)
  end

  def just(firstItem, *args)
    args = (firstItem.is_a? Array) ? firstItem : args.unshift(firstItem)
    
    args = (args.map {|v| v.to_s}) + (args.map {|v| v.to_sym})
    self.slice(*args)
  end

  def hawi
    HashWithIndifferentAccess.new self
  end
  alias_method :hwia, :hawi
  alias_method :indiff, :hawi

end

def nice_id
  # Unique, URL-able, dev-friendly. Try it yourself!
  return rand(10000).to_s unless $prod
  timestamp   = DateTime.now.strftime("%y%m%d%k%M%S%L")[1..14].to_i.to_s(36)  
  char        = (('a'..'z').to_a+('A'..'Z').to_a+('0'..'9').to_a)[rand(62)]
  mod_1000    = format('%03d', rand(1000))
  unique_id   = timestamp + char + mod_1000
  unique_id
end

def bp
	binding.pry
end

def admin?
  session.user && session.user.admin
end
