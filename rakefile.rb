task :default => [
       :prepare,
       #:test,
       :build,
       :install_android,
     ]


desc "Prepares flutter"
task :prepare do
  sh "flutter packages get"
  sh "flutter pub pub run  flutter_launcher_icons:main"
end

desc "build release apk"
task :build do
  sh "flutter build"
end

desc "install android apk"
task :install_android => [:build] do
  sh "adb install -r build/app/outputs/apk/release/app-release.apk"
end

desc 'stats'
task :stats do
  require 'terminal-table'
  total = 0
  table = Terminal::Table.new(headings: ["File", "LOC"]) do |table|
    Dir.glob('**/*.dart').each do |file|
      lines = File.read(file).split("\n").count
      total += lines
      table.add_row([file, lines])
    end
  end
  table.add_separator
  table.add_row(["total", total])
  puts table
end
