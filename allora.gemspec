# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "allora/version"

Gem::Specification.new do |s|
  s.name        = "allora"
  s.version     = Allora::VERSION
  s.authors     = ["d11wtq"]
  s.email       = ["chris@w3style.co.uk"]
  s.homepage    = "https://github.com/flippa/allora"
  s.summary     = %q{A ruby scheduler that keeps it simple, with support for distributed schedules}
  s.description = %q{Allora (Italian for "at that time") provides a replacement for the classic UNIX
                     cron, using nothing but ruby.  It is very small, easy to follow and relatively
                     feature-light.  It does support a locking mechanism, backed by Redis, or any
                     other custom implementation, which makes it possible to run the scheduler on
                     more than one server, without worrying about jobs executing more than once per
                     scheduled time.}

  s.rubyforge_project = "allora"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "redis"
end
