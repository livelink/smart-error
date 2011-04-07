require 'rubygems'
require 'optparse'
require 'redis'
require 'fileutils'
require 'pp'

R = Redis.new
WK = ENV['WKHTMLTOIMAGE'] || "wkhtmltoimage-amd64"

desc 'Generate thumbnail for host'
task :thumbnail do
	hosts = []
	if ENV["FILE"]
		hosts = IO.readlines(ENV["FILE"]).map { |ln| ln.chomp }.reject { |ln| ln.empty? }
	else
		hosts = [ENV["HOST"]].compact 
	end
	raise "Please specifiy HOST=<hostname> or FILE=<file-with-list-of-hostnames>" if hosts.empty?
	FileUtils.mkdir_p("public/small")
	hosts.each do |host|
		puts "#{host}"
		system("#{WK} --crop-h 641 http://#{host}/ - | convert -geometry 455x285 -quality 85 - public/small/#{host}.jpg")
	end
end

namespace :list do
desc 'List of hosts to email'
task :hosts do
	pp R.smembers('hosts/toEmail')
end

desc 'List of email addresses'
task :addresses do
	host = ENV["HOST"] or raise  "Please specifiy HOST=<hostname>"
	emails = R.smembers('hosts/'+host+'/emails')
	if emails
		puts emails.join(', ')
	else	
		raise "No emails found for #{host}"
	end
end

desc 'Dump database'
task :all do
	hosts = R.smembers('hosts/toEmail')
	if hosts
		hosts.each do |host|
			puts "Host: #{host}"
			emails = R.smembers('hosts/'+host+'/emails')
			if emails
				puts "    "+emails.join(', ')
			else
				puts "[??] No emails found for #{host}"
			end
		end
	else
		puts "Database is empty"
	end
end

desc 'Clear database'
task :clear do
	hosts = R.smembers('hosts/toEmail')
	if hosts
		hosts.each do |host|
			R.del("hosts/#{host}/emails")
		end	
		R.del("hosts/toEmail")
	else
		puts "Database is empty"
	end
end
end

