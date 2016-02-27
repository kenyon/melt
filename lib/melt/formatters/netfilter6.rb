module Melt
  module Formatters
    # IPv6 Netfilter implementation of a Melt formatter.
    class Netfilter6 < Netfilter
      # Return an IPv6 Netfilter String representation of the provided +rules+ Melt::Rule with the +policy+ policy.
      def emit_ruleset(rules, policy = :block)
        super(rules.select(&:ipv6?), policy)
      end

      def filename_fragment
        ['netfilter', 'rules.v6']
      end
    end
  end
end
