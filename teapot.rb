
teapot_version "0.8.0"

define_project "ARBrowser" do |project|
	project.add_author "Samuel Williams"
	project.license = "MIT License"
	
	project.version = "0.1.0"
end

define_target "transform-flow-browser-ios" do |target|
	target.depends :platform
	target.depends "Language/C++11"
	
	target.depends "Library/Euclid"
	target.depends "Library/TransformFlow"
	
	target.provides "Dependencies/TranformFlowBrowserIOS"
end

define_configuration "transform-flow-browser-ios" do |configuration|
	configuration.group do
		configuration[:source] = "https://github.com/dream-framework"
		
		configuration.require "project", :import => false
		
		configuration.require "platforms"
		configuration.require "dream"
		configuration.require "dream-imaging"
		configuration.require "euclid"
		configuration.require "opencv"
	end
	
	configuration.group do
		configuration[:source] = "https://github.com/HITLabNZ"
		
		configuration.require "transform-flow"
	end
	
	configuration[:run] = ["Library/TransformFlow"]
end
