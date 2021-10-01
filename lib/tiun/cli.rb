require 'optparse'
require 'ostruct'

require 'tiun'
require 'tiun/actor'

class Tiun::CLI
   DEFAULT_OPTIONS = {
      config: nil,
   }.to_os

   def option_parser
      @option_parser ||=
         OptionParser.new do |opts|
            opts.banner = "Usage: setup.rb [options & actions]"

            opts.on("-c", "--use-config=CONFIG", String, "use specific tiun config file to apply") do |config|
               options[:config] = config
            end

            opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
               options[:verbose] = v
            end

            opts.on("-h", "--help", "This help") do |v|
               puts opts
               puts "\nActions: \n#{actions.join("\n")}"
               exit
            end
         end

      if @argv
         @option_parser.default_argv.replace(@argv)
      elsif @option_parser.default_argv.empty?
         @option_parser.default_argv << "-h"
      end

      @option_parser
   end

   def options
      @options ||= DEFAULT_OPTIONS.dup
   end

   def actions
      @actions ||= parse.actions.select { |a| Tiun::Actor.kinds.include?(a) }
   end

   def tiun
      @tiun ||= options.config &&
         Tiun.setup_with(options.config) ||
         Tiun.setup
   end

   def default_parse
      @parse = OpenStruct.new(options: options, actions: option_parser.default_argv)
   end

   def parse!
      return @parse if @parse

      option_parser.parse!

      default_parse
   end

   def parse
      parse!
   rescue OptionParser::InvalidOption
      default_parse
   end

   def run
      actions.reduce({}.to_os) do |res, action_name|
         res[action_name] = Tiun::Actor.for!(action_name, tiun)

         res
      end.map do |action_name, actor|
         actor.apply_to(Tiun)
      end
   end

   def initialize argv = nil
      @argv = argv&.split(/\s+/)
   end
end
