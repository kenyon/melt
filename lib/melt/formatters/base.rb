# frozen_string_literal: true

module Melt
  module Formatters # :nodoc:
    module Base # :nodoc:
      # Returns the loopback IPv4 IPAddress
      #
      # @return [IPAddress]
      def self.loopback_ipv4
        IPAddress.parse('127.0.0.1')
      end

      # Returns the loopback IPv6 IPAddress
      #
      # @return [IPAddress]
      def self.loopback_ipv6
        IPAddress::IPv6::Loopback.new
      end

      # Returns a list of loopback addresses
      #
      # @return [Array<IPAddress>]
      def self.loopback_addresses
        [nil, loopback_ipv4, loopback_ipv6]
      end

      # Base class for Melt Formatter Rulesets
      class Ruleset
        def initialize
          @rule_formatter = Class.const_get(self.class.name.sub(/set$/, '')).new
        end

        def emit_header
          ["# Generated by melt v#{Melt::VERSION} on #{Time.now.strftime('%c')}"]
        end

        # Returns a String representation of the provided +rules+ Array of Melt::Rule with the +policy+ policy.
        #
        # @param rules [Array<Melt::Rule>] array of Melt::Rule.
        # @param _policy [Symbol] ruleset policy.
        # @return [String]
        def emit_ruleset(rules, _policy = nil)
          rules.collect { |rule| @rule_formatter.emit_rule(rule) }.join("\n")
        end

        # Filename for a firewall configuration fragment emitted by the formatter.
        #
        # @return [Array<String>]
        def filename_fragment
          raise 'Formatters#filename_fragment MUST be overriden'
        end
      end

      # Base class for Melt Formatter Rulesets
      class Rule
        protected

        # Returns the loopback IPAddress of the given +address_family+
        #
        # @param address_family [Symbol] the address family, +:inet+ or +:inet6+
        # @return [IPAddress,nil]
        def loopback_address(address_family)
          case address_family
          when :inet then Melt::Formatters::Base.loopback_ipv4
          when :inet6 then Melt::Formatters::Base.loopback_ipv6
          when nil then nil
          else raise "Unsupported address family #{address_family.inspect}"
          end
        end

        # Return a string representation of the +host+ IPAddress as a host or network.
        # @param host [IPAddress]
        # @return [String] IP address
        def emit_address(host)
          if host.ipv4? && host.prefix.to_i == 32 || host.ipv6? && host.prefix.to_i == 128
            host.to_s
          else
            host.to_string
          end
        end

        # Return a string representation of the +port+ port.
        # #param port [Integer,Range]
        # @return [String] Port
        def emit_port(port)
          case port
          when Integer
            port.to_s
          when Range
            "#{port.begin}:#{port.end}"
          end
        end
      end
    end
  end
end
