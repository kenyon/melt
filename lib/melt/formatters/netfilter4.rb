module Melt
  module Formatters
    # IPv4 Netfilter implementation of a Melt formatter.
    class Netfilter4 < Netfilter
      # Return an IPv4 Netfilter String representation of the provided +rule+ Rule.
      def emit_ruleset(rules)
        super(rules.select { |x| x.ipv4? })
      end
    end
  end
end
