require 'mysql2'

hosts = %w(localhost)

source_client = Mysql2::Client.new(host: 'localhost', username: 'root', database: 'zones_fix')

databases = source_client.query("SHOW TABLES").map { |h| h['Tables_in_zones_fix'] }

def drop_pk(client, database)
  begin
    client.query("ALTER TABLE `property_zones` DROP PRIMARY KEY")
  rescue
    puts "#{database}: Couldn't drop primary key"
  end
end


def add_pk(client, database)
  begin
    client.query("ALTER TABLE `property_zones` ADD PRIMARY KEY (`id`)")
  rescue
    puts "#{database}: <<<<<<<<<< could not add primary key >>>>>>>>>>>>>."
  end
end

hosts.each do |host|
  client = Mysql2::Client.new(host: host, username: 'root')
  client.query("SHOW DATABASES").each do |row|
    database = row["Database"]
    if database =~ /\Acms_/
      puts "\n\n--------- #{database} ------------"
      if databases.include?(database)
        client.query("USE #{database}")
        result = client.query('select count(1) as ct from schema_migrations where version = "20170831213934"')
        if result.first['ct'] > 0
          source_client.query("select * from #{database}").each do |source_zone|

            drop_pk(client, database)

            result = client.query("SELECT id,name from property_zones WHERE name = '#{source_zone['name']}'")
            puts result.first

            query = <<-SQL
              UPDATE property_zones SET id = #{source_zone['zoneid_pk']} WHERE name = "#{source_zone['name']}"
            SQL
            puts query
            client.query(query)

            add_pk(client, database)
          end
          source_client.query("RENAME TABLE #{database} TO #{database}_done")
        else
          puts "#{database}: hasn't run the dodgy migration"
        end
      else
        puts "#{database}: couldn't find in zones_fix db"
      end
    end
  end
end
