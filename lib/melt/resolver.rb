require 'ipaddress'
require 'resolv'

module Melt
  class Resolver
    def self.get_instance
      @@instance ||= new
    end

    def resolv(hostname, address_family = nil)
      addr = IPAddress.parse(hostname)
      return[addr]
    rescue
      result = []
      result += @dns.getresources(hostname, Resolv::DNS::Resource::IN::AAAA).collect { |r| IPAddress.parse(r.address.to_s) } if address_family.nil? or address_family == :inet6
      result += @dns.getresources(hostname, Resolv::DNS::Resource::IN::A).collect { |r| IPAddress.parse(r.address.to_s) } if address_family.nil? or address_family == :inet
      result
    end
  private
    def initialize
      @dns = Resolv::DNS.open
    end
  end
end
