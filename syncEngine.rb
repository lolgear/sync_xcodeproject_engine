#!/usr/bin/ruby

# required gems need to be installed:

# sudo gem install git
# sudo gem install xcodeproj


require 'git'
require 'rubygems'
require 'logger'
require 'xcodeproj'
require 'pp'
require 'optparse'
require 'yaml'

class MyLogger < Logger
	@@shared_instance = nil
	def MyLogger.shared_instance
		unless @@shared_instance
			MyLogger.setup()
		end
		@@shared_instance
	end

	def MyLogger.setup(log_level_message="", output_stream=nil)

		unless (output_stream)
			output_stream = STDOUT
		end

		@@shared_instance = Logger.new(output_stream)

		log_level_message ||= ""
		log_level_message = log_level_message.downcase
		case log_level_message
		when /^f(atal)?$/
			@@shared_instance.level = Logger::FATAL
		when /^e(rror)?$/
			@@shared_instance.level = Logger::ERROR
		when /^w(arn)?$/
			@@shared_instance.level = Logger::WARN
		when /^d(ebug)?$/
			@@shared_instance.level = Logger::DEBUG
		when /^i(nfo)?$/
			@@shared_instance.level = Logger::INFO
		else
			@@shared_instance.level = Logger::INFO
		end
	end

	def MyLogger.fatal(message)
		@@shared_instance.fatal message
		exit (1)
	end

	def MyLogger.error(message)
		@@shared_instance.error message
	end

	def MyLogger.warn(message)
		@@shared_instance.warn message
	end

	def MyLogger.info(message)
		@@shared_instance.info message
	end

	def MyLogger.debug(message)
		@@shared_instance.debug message
	end

end

# test section

def getPathToEngineGit
	return '/Users/mac/Documents/Projects/BitBucket/KulaFamily/KulaTechEngine'
end

def getPathToXcodeProj
	return '/Users/mac/Documents/Projects/BitBucket/KulaFamily/StarHit/star-hit/StarHit.xcodeproj'
end

def getPathForTestFile
	enginePath = getPathToEngineGit()
	return enginePath+'/'+'Sources/UI/ViewControllers/Content/Pins/KLBasePinnedViewController.h'
end

# test section end

def flat_hash_of_arrays(hash,string = "",delimiter="/",result = [])

	# choose delimiter
	hash.each do |key,value|

		# string dup for avoid string-reference (oh, Ruby)
		newString = string + delimiter + key
		# if value is array
		if value.is_a?(Array)

			# if array not empty
			value.each do |elementOfArray|

				# if a string, I dont need recursion, hah
				if elementOfArray.is_a?(String)
					resultString = newString + delimiter + elementOfArray
					# add new object
					result << resultString
				end

				# if a hash, I need recursion
				if elementOfArray.is_a?(Hash)
					flat_hash_of_arrays(elementOfArray,newString,delimiter,result)
				end

			end

		end

	end
end

def two_arrays_difference (firstArray,secondArray)
	oneTwo = firstArray - secondArray
	twoOne = secondArray - firstArray
	puts "one - two"
	pp oneTwo
	puts "two - one"
	pp twoOne
end

def two_arrays_difference_by_regex(firstArray,secondArray,regex)
	puts firstArray.select{
		|object|
		object[regex]
	}

	puts "\n\n"
	puts secondArray.select{
		|object|
		object[regex]
	}
end

def clear_array(array)
	# regex = /[.]framework.*?$/
	unless array.empty?
		array.map!{|object|
			object.sub! '/KulaTechEngine/', ""
			object
			# object[regex] ? object.sub!(regex,".framework") : object
		}
	end
	# after clear, banish duplicates
	array.uniq!
end

# banish localization and datamodel for now
def banish_unnecessary_types(array)
	regex = /GitSettings|[.]xccurrentversion|([.]md$)/
	array.reject!{
		|object|
		object =~ regex
	}
	array.reject!{
		|object|
		object.nil?
	}

end

def prepare_localization_from_files_to_project(array)
	filterRegex = /[.]lproj/
	substitudeRegex = /([\w-]+)[.]lproj\/(\w+)[.]strings/
	replacementExpression = '\2.strings/\1'
	options = {
		"filterRegex" => filterRegex,
		"substitudeRegex" => substitudeRegex,
		"replacementExpression" => replacementExpression
	}
	filter_array_with_substitution_and_replacement(array,options)
end

def prepare_localization_from_project_to_files(array)
	filterRegex = /[.]strings/
	substitudeRegex = /([\w-]+)[.]strings\/([\w-]+)/
	replacementExpression = '\2.lproj/\1.strings'
	options = {
		"filterRegex" => filterRegex,
		"substitudeRegex" => substitudeRegex,
		"replacementExpression" => replacementExpression
	}
	filter_array_with_substitution_and_replacement(array,options)
end

def prepare_datamodel_from_files_to_project(array)
	filterRegex = /xcdatamodel/
	substitudeRegex = /xcdatamodel\/.+/
	replacementExpression = 'xcdatamodel'
	options = {
		"filterRegex" => filterRegex,
		"substitudeRegex" => substitudeRegex,
		"replacementExpression" => replacementExpression
	}
	filter_array_with_substitution_and_replacement(array,options)

end

def prepare_framework_from_files_to_project(array)
	filterRegex = /[.]framework\/.*?/
	substitudeRegex = /[.]framework\/.+/
	replacementExpression = '.framework'
	options = {
		"filterRegex" => filterRegex,
		"substitudeRegex" => substitudeRegex,
		"replacementExpression" => replacementExpression
	}
	filter_array_with_substitution_and_replacement(array,options)

end

def prepare_bundle_from_files_to_project(array)
	filterRegex = /bundle/
	substitudeRegex = /bundle\/.+/
	replacementExpression = 'bundle'
	options = {
		"filterRegex" => filterRegex,
		"substitudeRegex" => substitudeRegex,
		"replacementExpression" => replacementExpression
	}
	filter_array_with_substitution_and_replacement(array,options)
end


def filter_array_with_substitution_and_replacement(array,options={})

	MyLogger.debug options
	return array unless %w(filterRegex substitudeRegex replacementExpression).any? {|key| options.has_key? key}
	filterRegex = options["filterRegex"]
	substitudeRegex = options["substitudeRegex"]
	replacementExpression = options["replacementExpression"]
	array.select{|object|
		object =~ filterRegex
	}.map!{|object|
		object.sub!(substitudeRegex,replacementExpression)
	}

end


# implement framework handlers ... hmm
# implement kula model handlers (cut /contents and .xcurrentversion)
# implement localization handlers (do replace (see in regex) )
# remove frameworks/kula model handlers/locaization

def save_project(project)
	project.save
	# project.pretty_print()
end

def remove_empty_groups_from_project(project)
	project.main_group.recursive_children_groups.each{ |child|
			if child.empty?
				child.remove_from_project()
			end
	}
end

# phase is SourcesBuildPhase Xcodeproj::Project::Object::PBXSourcesBuildPhase
# extensions are .h .m

# phase is FrameworksBuildPhase Xcodeproj::Project::Object::PBXFrameworksBuildPhase
# extensions are .framework .a

# phase is ResourcesBuildPhase Xcodeproj::Project::Object::PBXResourcesBuildPhase
# extensions are .json .js .html .css .png .txt .bundle

# phase is ShellScriptBuildPhase Xcodeproj::Project::Object::PBXShellScriptBuildPhase
# extensions are .pl .rb .py .sh etc ...

def remove_files_from_project_in_group(array,project,group)

	# basic checks
	raise "project is not a Xcode Project instance" unless project.is_a?(Xcodeproj::Project)
	raise "group is not a Group instance" unless group.is_a?(Xcodeproj::Project::Object::PBXGroup)

	# return if array is empty
	if array.empty?
		MyLogger.info "all files have been already removed!"
		return
	end

	# find build phases
	current_target = project.targets.find{ |target|
		target.display_name !~ /Tests/
	}

	# target not found
	unless current_target
		MyLogger.fatal "can't find any target!"
	end

	# remove build files
	current_target.build_phases.each{ |phase|
		all_files = phase.files

		unless all_files.empty?
			all_files.each{ |file|
					MyLogger.debug "I have found file with extension Bundle #{file.display_name} in phase #{phase.display_name}"
					MyLogger.debug "Associated file is: #{file.file_ref.display_name}"
					if array.include?(file.file_ref.display_name)
						phase.remove_build_file(file)
					end
					# file_ref.remove_from_project()
			}
		end
	}

	array.each{
		|object|

		# file to be removed finded
		MyLogger.debug "object with build files:#{object}"
		file = group[object]

		# remove file from list
		removedFile = project.files.delete(file)

		# remove references
		if removedFile
			removedFile.build_files.each{
				|referrer|
				MyLogger.debug "referrer is : #{referrer.display_name}"
				if referrer
					removedFile.remove_referrer(referrer)
					referrer.remove_from_project()
				end
			}
		end

		# remove target

		removedFile.remove_from_project()
	}

end

def add_files_to_project_in_group(array,project,group)

	# basic checks
	unless project.is_a?(Xcodeproj::Project)
		MyLogger.fatal "project is not a Xcode Project instance"
	end
	unless group.is_a?(Xcodeproj::Project::Object::PBXGroup)
		MyLogger.fatal "group is not a Group instance"
	end

	# return if array is empty
	if array.empty?
		MyLogger.info "all files have been already added!"
		return
	end


	added_file_ref_array = []

	# take correct files here
	MyLogger.info "add files as references... "
	array.each{ |element|
		# check for nil
		next unless element

		splitted = element.split('/')
		group_path = splitted[0..-2]
		file_name = splitted.last


		# needed for adding to build phases
		added_file_ref = nil

		# second parameter have value: 'true'
		# this means that it will create all subpaths
		group_for_file = group.find_subpath(group_path,true)
		if group_for_file

			# bug? after create group will have name but don't have path... bad-bad
			unless group_for_file.is_a?(Xcodeproj::Project::Object::PBXVariantGroup)
				unless group_for_file.path
					if group_for_file.empty?
						group_for_file.path = group_for_file.name
					end
				end
			end

			MyLogger.debug "in group: #{group_for_file.display_name}"
			MyLogger.debug "I want to add #{element}"
			# add localizable strings
			if group_for_file.is_a?(Xcodeproj::Project::Object::PBXVariantGroup)
				# restore for localizable strings
				prepared = prepare_localization_from_project_to_files([element])
				prepared = prepared[0]
				MyLogger.debug "after preparation: #{prepared}"
				prepared_path = prepared.sub(/.+?#{group_for_file.parent.display_name}\//,'')
				MyLogger.debug "I have #{group_for_file.parent.display_name}"
				MyLogger.debug "I have prepared_path: #{prepared_path}"
				added_file_ref = group_for_file.new_file(prepared_path)
				added_file_ref.name = file_name
				next
			else
				added_file_ref = group_for_file.new_file(file_name)
			end

			if added_file_ref

				# put file ref to build phase array
				added_file_ref_array << {
					'extension' => added_file_ref.display_name[/([.].+?)$/],
					'file' => added_file_ref
					}
			end

		end
	}

	# return if array is empty
	if added_file_ref_array.empty?
		MyLogger.info "all files have been already added to build phases!"
		return
	end

	# find build phases
	current_target = project.targets.find{ |target|
		target.display_name !~ /Tests/
	}

	# target not found
	unless current_target
		MyLogger.fatal "can't find any target!"
	end

	build_phases_hash = {}

	current_target.build_phases.each{ |phase|
		if phase.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
			build_phases_hash['Sources'] = {'extensions'=>'.m', 'phase' => phase}
		end
		if phase.is_a?(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)
			build_phases_hash['Frameworks'] = {'extensions'=>'.framework|.a', 'phase' => phase}
		end
		if phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
			build_phases_hash['Resources'] = {'extensions'=>'.json|.js|.html|.css|.png|.txt|.bundle','phase' => phase}
		end
		}

	MyLogger.info "add files to build phases..."
	added_file_ref_array.each{ |object|

		phase = nil
		if object['extension'] =~ /^#{build_phases_hash['Sources']['extensions']}$/
			phase = build_phases_hash['Sources']['phase']
		elsif object['extension'] =~ /^#{build_phases_hash['Frameworks']['extensions']}$/
			phase = build_phases_hash['Frameworks']['phase']
		elsif object['extension'] =~ /^#{build_phases_hash['Resources']['extensions']}$/
			phase = build_phases_hash['Resources']['phase']
		else
			# nothing
		end

		added_file_ref = object['file']
		if phase
			MyLogger.debug "I will add file ref: #{object['file'].display_name} to phase: #{phase.display_name}"
			unless phase.include?(added_file_ref)
				# second parameter has value 'true' because it has power to avoid duplicates
				phase.add_file_reference(added_file_ref,true)
			else
				MyLogger.debug "I've already added file ref: #{object['file'].display_name} to phase: #{phase.display_name}"
			end
		end

	}

end

def update_current_version_of_data_model(project)

	# basic checks
	unless project.is_a?(Xcodeproj::Project)
		MyLogger.fatal "project is not a Xcode Project instance"
	end

	# search latest data model
	model_version_group = project.main_group.recursive_children.find{
		|child|
		child.is_a?(Xcodeproj::Project::Object::XCVersionGroup)
	}

	if model_version_group
		unless model_version_group.empty?
			# sort by number and find largest
			latest_version = model_version_group.children.sort{|x,y| x.display_name[/\d+/].to_i <=> y.display_name[/\d+/].to_i}.last

			# already latest?
			if (model_version_group.current_version == latest_version)
				MyLogger.info "data model version is up to date: #{latest_version.display_name}"
				return
			end

			# I will change version
			# Since it is ruby, I need to check current version for nil, uh
			model_current_version_name = "version not set yet"
			if model_version_group.current_version
				model_current_version_name = model_version_group.current_version.display_name
			end
			MyLogger.info "update data model version from current: #{model_current_version_name} to latest: #{latest_version.display_name}"

			def model_version_group.current_version=(version)
				@current_version = version
			end

			model_version_group.current_version = latest_version
		end
	end
end

def get_engine_files_from_path(path)

	gitObject = Git.open(path,:log => nil) #Logger.new(STDERR)

	unless gitObject
		MyLogger.info "I can't open git at path: #{path} !!!"
	end


	engineFilesFromGit = gitObject.gtree("HEAD").full_tree

	unless engineFilesFromGit.empty?
		engineFilesFromGit.map!{ |object|
			object.split(' ')[-1]
		}
	else
		MyLogger.fatal "I can't use git at path: #{path} because it doesn't contain files!"
	end

	engineFilesFromGit

end

def get_project_and_project_files_and_engine_group_from_path_and_key(path, key)

	xcodeProject = Xcodeproj::Project.open(path)

	unless xcodeProject
		MyLogger.fatal "I can't open project at path: #{path} !!!"
	end

	engineGroup = xcodeProject.main_group.children.select{|obj| obj.display_name == key}
	engineGroup = engineGroup[0]

	unless engineGroup
		MyLogger.fatal "I can't find engine group in project by key: #{key} at path: #{path}"
	end
	projectFiles = xcodeProject.files.select{|file|
										file.hierarchy_path =~ /#{key}/
								 }.map{|file|
								 	file.hierarchy_path
								 }

	unless projectFiles
		MyLogger.fatal "I can't find files in engine group: #{key} at project path: #{path}"
	end

	return [xcodeProject, projectFiles, engineGroup]

end

def MainWork(options={})


	if options[:test]
		options[:log_level] = "DEBUG"
		options[:engine_path] ||= getPathToEngineGit()
		options[:project_path] ||= getPathToXcodeProj()
	end

	# setup engine
	options[:engine_key] ||= "KulaTechEngine"

	# setup logger
	MyLogger.setup(options[:log_level], options.has_key?(:output_stream) ? options[:output_stream] : nil)


	MyLogger.debug "options are: #{options.pretty_inspect}"

	# check for parameters
	missing = [:engine_path, :project_path] - options.keys
	unless missing.empty?
		MyLogger.fatal "I don't have parameter! #{missing}"
	end

	if options[:dry_run]
		MyLogger.debug "Run is dry... exit"
		exit(0)
	end

	# get git files
	engineFilesFromGit = get_engine_files_from_path(options[:engine_path])

	# this is a hash with keys - filepaths
	# engineFilesFromGit = gitObject.ls_files.values.map{|object| object["path"]}

	# refactoring needed
	xcodeProject , projectFiles, engineGroup = get_project_and_project_files_and_engine_group_from_path_and_key(options[:project_path],options[:engine_key])
	# choose correct object

	clear_array(projectFiles)
	clear_array(engineFilesFromGit)

	prepare_framework_from_files_to_project(projectFiles)

	prepare_framework_from_files_to_project(engineFilesFromGit)
	prepare_localization_from_files_to_project(engineFilesFromGit)
	prepare_datamodel_from_files_to_project(engineFilesFromGit)
	prepare_bundle_from_files_to_project(engineFilesFromGit)

	banish_unnecessary_types(engineFilesFromGit)
	banish_unnecessary_types(projectFiles)

	# search files to be added or removed

	filesToBeAdded = engineFilesFromGit - projectFiles

	filesToBeRemoved = projectFiles - engineFilesFromGit

	MyLogger.debug "I will add: filesToBeAdded"
	MyLogger.debug filesToBeAdded.pretty_inspect
	MyLogger.debug "I will remove: filesToBeRemoved"
	MyLogger.debug filesToBeRemoved.pretty_inspect

	if options[:changes]
		MyLogger.debug "All changes've already seen... exit"
		exit()
	end

	# remove files from project

	MyLogger.info "remove files... "
	remove_files_from_project_in_group(filesToBeRemoved,xcodeProject,engineGroup)

	# remove empty groups
	MyLogger.info "remove empty groups... "
	remove_empty_groups_from_project(xcodeProject)

	# add files to project
	MyLogger.info "add files... "
	add_files_to_project_in_group(filesToBeAdded,xcodeProject,engineGroup)

	# update current version of data model to latest
	MyLogger.info "update current version of data model... "
	update_current_version_of_data_model(xcodeProject)

	# don't save until you will be sure
	MyLogger.info "save project... "
	save_project(xcodeProject)

	MyLogger.info "done!"

end

def HelpMessage(options)
	# %x[rdoc $0]
	# not ok
	puts <<-__HELP__

	#{options.help}

	this script will help you sync your project

	First, it take two arguments:
	-p <PATH> your project file (.xcodeproj) path
	-e <PATH> your engine path

	after that, script will sync engine and your project.

	now this script nearly in a normal usage.
	tests needed

	---------------
	Add to project
	---------------
	Editor -> Add Build Phase -> Add Script Phase

	Shell: /bin/sh
	Script:
	~/Tools/syncEngine.rb -e <#../../CoreProject#> -p "$PROJECT_FILE_PATH"

	__HELP__
end


# options parser:
options = {}


OptionParser.new do |opts|
	opts.banner = "Usage: syncRuby.rb [options]"


	opts.on('-e', '--engine NAME', 'Engine path') { |v| options[:engine_path] = v }
	opts.on('-p', '--project NAME', 'Project path') { |v| options[:project_path] = v }
	opts.on('-t', '--test', 'Test option') {|v| options[:test] = v}
	opts.on('-l', '--log_level LEVEL', 'Logger level of warning') {|v| options[:log_level] = v}
	opts.on('-o', '--output_log OUTPUT', 'Logger output stream') {|v| options[:output_stream] = v}
	opts.on('-d', '--dry_run', 'Dry run to see all options') {|v| options[:dry_run] = v}
	opts.on('-c','--changes','See all files that added or removed to project from engine') {|v| options[:changes] = v}
	# help
	opts.on('-h', '--help', 'Help option') { HelpMessage(opts); exit()}
end.parse!


MainWork(options)

