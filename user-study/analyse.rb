#!/usr/bin/env ruby

require 'csv'
require './trial'

FOUND = /Found/
HIT = /Hit/
MARKER = /Marker/

trial_paths = Dir.glob("**/*.csv")

trials = trial_paths.collect do |path|
	trial = Trial.new
	
	marker = nil
	found = nil
	hit = nil
	
	CSV.foreach(path) do |row|
		if row[1] =~ MARKER
			marker = row
			hit = found = nil
		end
		
		if row[1] =~ FOUND
			found ||= row
		end
		
		if row[1] =~ HIT
			hit = row
			trial.add_event(marker[3].strip, hit[2].to_f - found[2].to_f)
		end
	end
	
	trial
end

trials.each do |trial|
	puts trial.inspect
end
