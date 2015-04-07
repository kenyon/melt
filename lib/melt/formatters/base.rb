module Melt
  module Formatters # :nodoc:
    # Base class for Melt Formatters.
    class Base
      def initialize
        @loopback_addresses = [nil, loopback_address(:inet), loopback_address(:inet6)]
      end

      # Returns a String representation of the provided +rules+ Array of Rule with the +policy+ policy.
      def emit_ruleset(rules, policy = nil)
        rules.collect { |rule| emit_rule(rule) }.join("\n")
      end

      # Returns a loopback address in the specified address family.
      def loopback_address(address_family)
        case address_family
          when :inet then IPAddress.parse('127.0.0.1')
          when :inet6 then IPAddress::IPv6::Loopback.new
          when nil then nil
          else raise "Unsupported address family #{address_family.inspect}"
        end
      end
    protected
      # Return a string representation of the +host+ IPAddress as a host or network.
      def emit_address(host)
        if host.ipv4? && host.prefix.to_i == 32 ||
          host.ipv6? && host.prefix.to_i == 128 then
          host.to_s
        else
          host.to_string
        end
      end
    end
  end
end
