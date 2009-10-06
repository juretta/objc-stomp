# Author: Stefan Saasen


task :default => [:analyze]

desc "Analyze code"
task :analyze => [:clean] do
  # Add to 'scan-build' Path - e.g. /Users/stefan/dev/iphone/checker-75
  begin
    sh "scan-build -v -V xcodebuild -configuration Debug" do |ok, res|
      puts "Failed to run the analyze task (status: #{res.exitstatus})" if !ok
    end
  rescue => e
    puts "Please install the LLVM/Clang checker: http://clang.llvm.org/StaticAnalysis.html"
    puts "and add the directory containing the 'scan-build' binary to your $PATH"
  end
end

desc "Clean build artifacts"
task :clean do
  sh "xcodebuild clean"
end