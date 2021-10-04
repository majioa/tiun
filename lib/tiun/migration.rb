require 'tiun/version'

module Tiun::Migration
   Proxy = Struct.new(:name, :version, :code, :scope) do
      def initialize(name, version, code, scope)
         super
         @migration = nil
      end

      def basename
         ""
      end

      delegate :migrate, :announce, :write, :disable_ddl_transaction, to: :migration

      private

      def migration
         @migration ||= load_migration
      end

      def load_migration
         Tiun.string_eval(code, name)
         name.constantize.new(name, version)
      end
   end

   MigrationTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "automigration.rb.erb")))

   EMBED = <<-END
      class ActiveRecord::MigrationContext
         alias :__old_migrations :migrations

         def migrations
            (Tiun.proxied_migrations | __old_migrations).sort_by(&:version)
         end
       end
   END

   def base_migration
      @base_migration ||= ActiveRecord::Migration[5.2]
   end

   def migration_of context, name
      context.migration || "Create" + model_title_of(context, name).pluralize.camelize
   end

   def migration_fields_for context, name
      model = model_title_of(context, name)

      fields = search_for(:types, model).fields | defaults.fields

      fields.map do |attrs|
         type = detect_type(attrs.kind)
         type && { name: attrs.name, type: type, options: {} } || nil
      end.compact
   end

   def load_migrations_from config
      config_reduce(config, migrations) do |migrations, name, context|
         migration_name = migration_of(context, name)

         if !search_for(:migrations, migration_name)
            table_title = table_title_of(context, name)
            migration_fields = migration_fields_for(context, name)
            code = MigrationTemplate.result(binding)
            timestamp = context.timestamp

            if timestamp
               migrations << { name: migration_name, code: code, timestamp: timestamp }.to_os
            else
               error :no_timestamp_defined_for_migration, {name: migration_name, code: code}
            end
         end

         migrations
      end
   end

   def search_all_for kind, value
      send(kind).select {|x| x.name == value }
   end

   def migrations
      @migrations ||= []
   end

   def proxied_migrations
      migrations.map do |m|
         Proxy.new(m.name, m.timestamp.utc.strftime("%Y%m%d%H%M%S").to_i, m.code, nil)
      end
   end

   def setup_migrations
      Kernel.module_eval(EMBED)
   end
end
