require 'rubygems'
require 'open-uri'

class StatusPage
  attr_reader :oauth

  def initialize(args=nil)
    @oauth = "adeac0389fd4fb8a1519c2590f36263708e9574c6d5560f7e6808acfe1261ffe"

    start(args) if args
  end

  def start(args=[])
    command = args.shift
    puts args.class
    if self.respond_to? command
      send(command, *args)
    else
      puts "Command not recognized"
    end
    puts command
    puts args
  end

  def profile(*args)
    puts `curl https://api.statuspage.io/v1/pages/#{args[0]}.json -H "Authorization: OAuth #{@oauth}"`
    puts "XXX"
    puts args.inspect
    puts args.class
  end

end
