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
  puts "lines: #{Dir.glob("**/*.dart").inject(0) {|memo, f|memo + File.read(f).split("\n").count}}"
end
