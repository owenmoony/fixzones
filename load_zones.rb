require 'mysql2'

client = Mysql2::Client.new(host: 'localhost', username: 'root', database: 'zones_fix')

begin
  client.query('CREATE DATABASE zones_fix')
rescue
  puts "couldn't create database - perhaps it exists"
end

client.query('USE zones_fix')

File.read('source.txt').each_line do |line|
  filename, insert = line.match(/\A(.*?\.gz):(.*)/).captures
  database_name = filename.match(/\A(cms.*?)\./).captures.first
  client.query <<-SQL
    CREATE TABLE `#{database_name}` (
      `zoneid_pk` smallint(3),
      `name` varchar(50) NOT NULL DEFAULT '',
      `ts` timestamp,
      `office_group_id` int(11) NOT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  SQL
  insert.gsub!(/property_zones/, database_name)
  client.query(insert)
end

puts "done"