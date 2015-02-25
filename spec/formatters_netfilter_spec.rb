require 'melt'

module Melt
  module Formatters
    RSpec.describe Netfilter do
      it 'formats simple rules' do
        formatter = Netfilter.new

        rule = Rule.new(action: :pass, dir: :in, proto: :tcp, dst: { host: nil, port: 80 })
        expect(formatter.emit_rule(rule)).to eq('-A INPUT -p tcp --dport 80 -j ACCEPT')

        rule = Rule.new(action: :pass, dir: :in, iface: 'lo')
        expect(formatter.emit_rule(rule)).to eq('-A INPUT -i lo -j ACCEPT')

        rule = Rule.new(action: :block, dir: :in, iface: '!lo', dst: { host: IPAddress.parse('127.0.0.0/8') })
        expect(formatter.emit_rule(rule)).to eq('-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT')

        rule = Rule.new(action: :pass, dir: :out)
        expect(formatter.emit_rule(rule)).to eq('-A OUTPUT -j ACCEPT')
      end
    end
  end
end
