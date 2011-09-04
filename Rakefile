require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "has_custom_fields"
    gem.summary = %Q{The easy way to add custom fields to any Rails model.}
    gem.description = %Q{Uses a vertical schema to add custom fields.}
    gem.email = "kylejginavan@gmail.com"
    gem.homepage = "http://github.com/kylejginavan/has_custom_fields"
    gem.add_dependency('builder')
    gem.authors = ["kylejginavan"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "has_custom_fields (or a dependency) not available. Install it with: gem install has_custom_fields"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "constantations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end




# require 'rake'
# require 'rake/testtask'
# require 'rake/rdoctask'
# require 'spec/rake/spectask'
# require 'spec/rake/verify_rcov'
# 
# plugin_name = 'acts_as_custom_field_model'
# 
# desc 'Default: run specs.'
# task :default => :spec
# 
# desc "Run the specs for #{plugin_name}"
# Spec::Rake::SpecTask.new(:spec) do |t|
#   t.spec_files = FileList['spec/**/*_spec.rb']
#   t.spec_opts  = ["--colour"]
# end
# 
# namespace :spec do
#   desc "Generate RCov report for #{plugin_name}"
#   Spec::Rake::SpecTask.new(:rcov) do |t|
#     t.spec_files  = FileList['spec/**/*_spec.rb']
#     t.rcov        = true
#     t.rcov_dir    = 'doc/coverage'
#     t.rcov_opts   = ['--text-report', '--exclude', "spec/,rcov.rb,#{File.expand_path(File.join(File.dirname(__FILE__),'../../..'))}"] 
#   end
# 
#   namespace :rcov do
#     desc "Verify RCov threshold for #{plugin_name}"
#     RCov::VerifyTask.new(:verify => "spec:rcov") do |t|
#       t.threshold = 100.0
#       t.index_html = File.join(File.dirname(__FILE__), 'doc/coverage/index.html')
#     end
#   end
#   
#   desc "Generate specdoc for #{plugin_name}"
#   Spec::Rake::SpecTask.new(:doc) do |t|
#     t.spec_files  = FileList['spec/**/*_spec.rb']
#     t.spec_opts   = ["--format", "specdoc:SPECDOC"]
#    end
# 
#   namespace :doc do
#     desc "Generate html specdoc for #{plugin_name}"
#     Spec::Rake::SpecTask.new(:html => :rdoc) do |t|
#       t.spec_files    = FileList['spec/**/*_spec.rb']
#       t.spec_opts     = ["--format", "html:doc/rspec_report.html", "--diff"]
#     end
#   end
# end
# 
# task :rdoc => :doc
# task "SPECDOC" => "spec:doc"
# 
# desc "Generate rdoc for #{plugin_name}"
# Rake::RDocTask.new(:doc) do |t|
#   t.rdoc_dir = 'doc'
#   t.main     = 'README.rdoc'
#   t.title    = "#{plugin_name}"
#   t.template = ENV['RDOC_TEMPLATE']
#   t.options  = ['--line-numbers', '--inline-source', '--all']
#   t.rdoc_files.include('README.rdoc', 'SPECDOC', 'MIT-LICENSE', 'CHANGELOG')
#   t.rdoc_files.include('lib/**/*.rb')
# end
# 
# namespace :doc do 
#   desc "Generate all documentation (rdoc, specdoc, specdoc html and rcov) for #{plugin_name}"
#   task :all => ["spec:doc:html", "spec:doc", "spec:rcov", "doc"]
# end