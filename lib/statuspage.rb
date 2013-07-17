require 'rubygems'
require 'httparty'

class StatusPage
  STATUSES = %w(operational degraded_performance partial_outage major_outage)

  def initialize(args=nil)
    @oauth = "adeac0389fd4fb8a1519c2590f36263708e9574c6d5560f7e6808acfe1261ffe"
    @base_url = "https://api.statuspage.io/v1/pages/"
    @page = "p9qz8c9gtcnh"

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
  end

  def profile(*args)
    results = httparty_send :get, "#{@base_url}#{@page}.json"
    puts results
    puts results["allow_sms_subscribers"]
  end

  def components(*args)
    if args.empty?
      results = httparty_send :get, "#{@base_url}#{@page}/components.json"
      puts results
    else
      if STATUSES.include? args[1]
        results = httparty_send :patch, "#{@base_url}#{@page}/components/#{args[0]}.json", :body => {"component[status]" => args[1]}
        puts results
      else
        puts "Invalid status"
      end
    end
  end

  def incidents(*args)
    if args.empty?
      results = httparty_send :get, "#{@base_url}#{@page}/incidents.json"
      puts results
    else
      options = { :body => { "incident[name]" => args[0], "incident[status]" => args[1],  "incident[message]" => args[3] } }
      results = httparty_send :post, "#{@base_url}#{@page}/incidents.json", options
      puts results
    end
  end

  private

  def httparty_send(action, url, options={})
    puts url
    options.merge!(:headers => { "Authorization: OAuth" => @oauth })
    puts "OPT: #{options}"
    HTTParty.send(action, url, options)
  end
end
