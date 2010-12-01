directory_dependency_extension=dirdep

directory_marker_file_extension=dirmarker
directory_marker_file=.directory.$(directory_marker_file_extension)

config=debug
config_prefix=$(config)

module_name=testmod
module_source_dir=
module_dep_dir=dep
module_dep_path=$(config_prefix)/$(module_dep_dir)

module_target=$(module_name)

source_dependency=$(module_dep_path)/src.$(directory_dependency_extension)

$(module_target): $(source_dependency)

%/$(directory_marker_file):
	mkdir -p $(@D)
	touch $@

.PRECIOUS: %/$(directory_marker_file)

.SECONDEXPANSION:
%.$(directory_dependency_extension): $$(@D)/$(directory_marker_file)
	touch $@

