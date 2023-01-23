require 'tiun/version'

module Tiun::Migration
   Proxy = Struct.new(:name, :timestamp, :code) do
      delegate :migrate, :announce, :write, :disable_ddl_transaction, to: :migration

      def basename
         ""
         # TODO fake name file
      end

      def scope
         nil
      end

      def version
         timestamp.utc.strftime("%Y%m%d%H%M%S").to_i
      end

      private

      def migration
         @migration ||= load_migration
      end

      def load_migration
         Tiun.string_eval(code, name)
         name.constantize.new(name, version)
      end

      def initialize(name, timestamp, code)
         super
         @migration = nil
      end
   end

   MigrationTemplate = ERB.new(IO.read(File.join(File.dirname(__FILE__), "automigration.rb.erb")))

   EMBED = <<-END
      class ActiveRecord::MigrationContext
         alias :__old_migrations :migrations

         def migrations
            (Tiun.migrations | __old_migrations).sort_by(&:version)
         end
       end
   END

   def base_migration
      @base_migration ||= ActiveRecord::Migration[5.2]
   end

   def migration_name_for type
      "Create" + type.name.pluralize.camelize
   end

   def fields_for type
      (type.fields || []) | (defaults.fields || [])
   end

   def migration_fields_for type
      fields_for(type).map do |attrs|
         type = detect_type(attrs.kind)
         type && { name: attrs.name, type: type, options: {} } || nil
      end.compact
   end

   def migrations
      return @migrations if @migrations

      @migrations =
         types.reduce([]) do |migrations, type|
            next migrations if type.parent

            migration_name = migration_name_for(type)

            if migrations.any? { |m| m.name == migration_name }
               error :duplicated_migration_found, {name: migration_name, type: type}
            else
               table_title = table_title_for(type)
               migration_fields = migration_fields_for(type)
               code = MigrationTemplate.result(binding)
               timestamp = type.timestamp

               if timestamp
                  migrations << Proxy.new(migration_name, type.timestamp, code)
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

   def setup_migrations
      Kernel.module_eval(EMBED)
   end
end

Migration = Tiun::Migration
