# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ShyCouch}
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Shy Inc.}, %q{Daniel Bryan}, %q{Cerales}]
  s.date = %q{2011-08-28}
  s.description = %q{Ruby API for CouchDB, designed to work with the Camping micro-framework.}
  s.email = %q{danbryan@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README",
    "Rakefile",
    "ShyCouch.gemspec",
    "VERSION",
    "lib/ShyCouch.rb",
    "lib/ShyCouch/data.rb",
    "lib/ShyCouch/fields.rb",
    "test/helper.rb",
    "test/old-test.rb",
    "test/old-tests.rb",
    "test/test_ShyCouch.rb",
    "test/test_camping_integration.rb",
    "test/test_couch_document.rb",
    "test/test_couchdb_api.rb",
    "test/test_couchdb_factory.rb",
    "test/test_design_documents.rb",
    "test/test_fields.rb",
    "test/test_views.rb"
  ]
  s.homepage = %q{http://github.com/Cerales/ShyCouch}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Ruby API for CouchDB, designed to work with the Camping micro-framework.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<sourcify>, ["~> 0.5.0"])
      s.add_development_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_runtime_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_runtime_dependency(%q<sourcify>, [">= 0"])
    else
      s.add_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<sourcify>, ["~> 0.5.0"])
      s.add_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_dependency(%q<ShyRubyJS>, [">= 0"])
      s.add_dependency(%q<sourcify>, [">= 0"])
    end
  else
    s.add_dependency(%q<ShyRubyJS>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<sourcify>, ["~> 0.5.0"])
    s.add_dependency(%q<ShyRubyJS>, [">= 0"])
    s.add_dependency(%q<ShyRubyJS>, [">= 0"])
    s.add_dependency(%q<sourcify>, [">= 0"])
  end
end

