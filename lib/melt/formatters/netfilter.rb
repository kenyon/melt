module Melt
  module Formatters
    # Netfilter implementation of a Melt formatter.
    class Netfilter < Base # :nodoc:
      # Returns a Netfilter String representation of the provided +rule+ Melt::Rule.
      def emit_rule(rule)
        if rule.nat?
          emit_postrouting_rule(rule)
        elsif rule.rdr?
          emit_prerouting_rule(rule)
        else
          emit_filter_rule(rule)
        end
      end

      # Returns a Netfilter String representation of the provided +rules+ Array of Melt::Rule with the +policy+ policy.
      def emit_ruleset(rules, policy = :block)
        nat_rules    = rules.select { |r| r.nat? || r.rdr? }
        filter_rules = rules.select { |r| [:pass, :block, :log].include?(r.action) }

        parts = []
        parts << "# Generated by melt v#{Melt::VERSION} on #{Time.now.strftime('%c')}"

        if nat_rules.count > 0
          parts << '*nat'
          parts << ':PREROUTING ACCEPT [0:0]'
          parts << ':INPUT ACCEPT [0:0]'
          parts << ':OUTPUT ACCEPT [0:0]'
          parts << ':POSTROUTING ACCEPT [0:0]'
          parts << super(nat_rules.select(&:rdr?))
          parts << super(nat_rules.select(&:nat?))
          parts << 'COMMIT'
        end

        parts << '*filter'
        parts << ":INPUT #{iptables_action(policy)} [0:0]"
        parts << ":FORWARD #{iptables_action(policy)} [0:0]"
        parts << ":OUTPUT #{iptables_action(policy)} [0:0]"
        parts << '-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'
        parts << super(filter_rules.select { |r| r.filter? && r.in? })
        parts << '-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'
        parts << super(filter_rules.select(&:fwd?))
        parts << super(filter_rules.select { |r| r.rdr? && !@loopback_addresses.include?(r.rdr_to_host) }.collect do |r|
          if r.dir == :in
            r.in ||= r.on
          else
            r.out ||= r.on
          end
          r.to.merge!(r.rdr_to.reject { |_k, v| v.nil? })
          r.rdr_to = nil
          r.dir = :fwd
          r.on = nil
          r
        end)
        parts << '-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'
        parts << super(filter_rules.select { |r| r.filter? && r.out? })
        parts << 'COMMIT'

        parts.reject(&:empty?).join("\n")
      end

      protected

      def emit_postrouting_rule(rule)
        "-A POSTROUTING -o #{rule.on} -j MASQUERADE"
      end

      def emit_prerouting_rule(rule)
        parts = ['-A PREROUTING']
        parts << emit_on(rule)
        parts << emit_proto(rule)
        parts << emit_src(rule)
        parts << emit_dst(rule)
        parts << emit_redirect_or_dnat(rule)
        pp_rule(parts)
      end

      def emit_filter_rule(rule)
        iptables_direction = { in: 'INPUT', out: 'OUTPUT', fwd: 'FORWARD' }
        parts = ["-A #{iptables_direction[rule.dir]}"]
        parts << emit_if(rule)
        parts << emit_proto(rule)
        parts << emit_src(rule)
        parts << emit_dst(rule)
        parts << emit_jump(rule)
        pp_rule(parts)
      end

      def emit_if(rule)
        if rule.on
          emit_on(rule)
        else
          emit_in_out(rule)
        end
      end

      def emit_on(rule)
        on_direction_flag = { in: '-i', out: '-o' }

        if rule.on && rule.dir
          matches = /(!)?(.*)/.match(rule.on)
          [matches[1], on_direction_flag[rule.dir], matches[2]].compact
        end
      end

      def emit_in_out(rule)
        parts = []
        parts << "-i #{rule.in}" if rule.in
        parts << "-o #{rule.out}" if rule.out
        parts
      end

      def emit_proto(rule)
        "-p #{rule.proto}" if rule.proto
      end

      def emit_src(rule)
        emit_endpoint_specification(:in, rule.src_host, rule.src_port)
      end

      def emit_dst(rule)
        emit_endpoint_specification(:out, rule.dst_host, rule.dst_port)
      end

      def emit_endpoint_specification(direction, host, port)
        flag = { in: 's', out: 'd' }[direction]
        parts = []
        parts << "-#{flag} #{emit_address(host)}" if host
        parts << "--#{flag}port #{port}" if port
        parts
      end

      def emit_redirect_or_dnat(rule)
        if @loopback_addresses.include?(rule.rdr_to_host)
          emit_redirect(rule)
        else
          emit_dnat(rule)
        end
      end

      def emit_redirect(rule)
        "-j REDIRECT --to-port #{rule.rdr_to_port}"
      end

      def emit_dnat(rule)
        "-j DNAT --to-destination #{rule.rdr_to_host}"
      end

      def emit_jump(rule)
        "-j #{iptables_action(rule)}"
      end

      private

      def pp_rule(parts)
        parts.flatten.compact.join(' ')
      end

      def iptables_action(rule_or_action, ret = false)
        case rule_or_action
        when :pass then 'ACCEPT'
        when :log then 'LOG'
        when :block then
          ret ? 'RETURN' : 'DROP'
        when Rule then iptables_action(rule_or_action.action, rule_or_action.return)
        end
      end
    end
  end
end
